"""Invoice API endpoints for upload, OCR extraction, and preview."""

import hashlib
from pathlib import Path
import time
from typing import List, Optional
from fastapi import APIRouter, File, HTTPException, UploadFile, status
from fastapi.responses import FileResponse
from pydantic import BaseModel

from ...core.config import settings
from ...schemas.invoice import InvoiceExtractedData, OCRResult
from ...services.extraction import get_extraction_service
from ...services.ocr_service import get_ocr_service

router = APIRouter(prefix="/api/invoices", tags=["Invoices"])

# Allowed photo image extensions
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}


class OCRExtractionResponse(BaseModel):
    """Response returned upon photo image upload and OCR scanning."""
    id: str
    filename: str
    file_hash_sha256: str
    image_url: str
    ocr_result: OCRResult
    extracted_data: InvoiceExtractedData
    line_count: int


@router.post("/ocr", response_model=OCRExtractionResponse, status_code=status.HTTP_201_CREATED)
async def upload_and_extract_ocr(file: UploadFile = File(...)):
    """Upload photo bill/invoice and scan with PaddleOCR."""
    filename = file.filename or "invoice_photo.jpg"
    ext = Path(filename).suffix.lower()

    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file type '{ext}'. Allowed image photo formats: {', '.join(sorted(ALLOWED_EXTENSIONS))}",
        )

    content = await file.read()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty.",
        )

    # Compute SHA-256 integrity hash per AGENTS.md Rule 80
    file_hash = hashlib.sha256(content).hexdigest()

    # Save original photo in DOCUMENT_ROOT/uploads/
    settings.ensure_directories()
    safe_filename = f"{file_hash[:16]}_{Path(filename).name}"
    saved_path = settings.DOCUMENT_ROOT / "uploads" / safe_filename
    saved_path.write_bytes(content)

    # Execute PaddleOCR extraction
    ocr_adapter = get_ocr_service()
    try:
        ocr_result = ocr_adapter.extract_from_image(content)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"OCR engine extraction failed: {str(e)}",
        )

    # Determine media type for multimodal extraction
    media_type = "image/jpeg"
    if ext == ".png":
        media_type = "image/png"
    elif ext == ".webp":
        media_type = "image/webp"
    elif ext == ".bmp":
        media_type = "image/bmp"

    # Execute Gemini Extraction into structured invoice fields
    extractor = get_extraction_service()
    extracted_data = extractor.extract(ocr_result, image_bytes=content, mime_type=media_type)

    invoice_id = f"INV-{int(time.time() * 1000) % 1000000:06d}"

    return OCRExtractionResponse(
        id=invoice_id,
        filename=filename,
        file_hash_sha256=file_hash,
        image_url=f"/api/invoices/file/{safe_filename}",
        ocr_result=ocr_result,
        extracted_data=extracted_data,
        line_count=len(ocr_result.lines),
    )


@router.post("/extract-text", response_model=InvoiceExtractedData)
async def extract_from_raw_ocr(ocr_result: OCRResult):
    """Directly run Gemini structured bill extraction on an existing OCR result payload."""
    extractor = get_extraction_service()
    return extractor.extract(ocr_result)


@router.get("/file/{filename}")
async def get_invoice_file(filename: str):
    """Serve uploaded invoice photo image for browser preview."""
    safe_name = Path(filename).name
    file_path = settings.DOCUMENT_ROOT / "uploads" / safe_name

    if not file_path.exists() or not file_path.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File not found")

    ext = file_path.suffix.lower()
    media_type = "image/jpeg"
    if ext == ".png":
        media_type = "image/png"
    elif ext == ".webp":
        media_type = "image/webp"

    return FileResponse(file_path, media_type=media_type)
