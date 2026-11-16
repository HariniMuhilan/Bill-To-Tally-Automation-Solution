"""Invoice API endpoints for upload, OCR extraction, and preview."""

import hashlib
import logging
from pathlib import Path
import re
import time
from typing import Optional
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import FileResponse
from pydantic import BaseModel
import sys

# Ensure project root and backend directory are in sys.path for direct execution or IDE tools
_current_dir = Path(__file__).resolve().parent
_project_root = _current_dir.parent.parent.parent.parent
if str(_project_root) not in sys.path:
    sys.path.insert(0, str(_project_root))
_backend_dir = _project_root / "backend"
if str(_backend_dir) not in sys.path:
    sys.path.insert(0, str(_backend_dir))

try:
    from backend.app.core.auth import AuthenticatedUser, get_current_user
    from backend.app.core.config import settings
    from backend.app.schemas.invoice import InvoiceExtractedData, OCRResult
    from backend.app.services.extraction import get_extraction_service
    from backend.app.services.ocr_service import MockOCRAdapter, get_ocr_service
except (ImportError, ValueError):
    try:
        from app.core.auth import AuthenticatedUser, get_current_user
        from app.core.config import settings
        from app.schemas.invoice import InvoiceExtractedData, OCRResult
        from app.services.extraction import get_extraction_service
        from app.services.ocr_service import MockOCRAdapter, get_ocr_service
    except (ImportError, ValueError):
        # pyrefly: ignore[missing-import]
        from ...core.auth import AuthenticatedUser, get_current_user
        # pyrefly: ignore[missing-import]
        from ...core.config import settings
        # pyrefly: ignore[missing-import]
        from ...schemas.invoice import InvoiceExtractedData, OCRResult
        # pyrefly: ignore[missing-import]
        from ...services.extraction import get_extraction_service
        # pyrefly: ignore[missing-import]
        from ...services.ocr_service import MockOCRAdapter, get_ocr_service

logger = logging.getLogger(__name__)
_SAFE_SEGMENT_RE = re.compile(r"[^a-zA-Z0-9_.-]")
_READ_CHUNK_SIZE = 65536

router = APIRouter(prefix="/api/invoices", tags=["Invoices"])

# Allowed photo image extensions
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}

STRONG_BILL_KEYWORDS = {
    'gstin', 'invoice', 'tax invoice', 'bill of supply', 'cgst', 'sgst', 'igst',
    'hsn', 'hsn/sac', 'sac code', 'grand total', 'subtotal', 'sub total',
    'cash memo', 'delivery challan', 'taxable value', 'taxable amount'
}

SECONDARY_BILL_KEYWORDS = {
    'total', 'bill', 'tax', 'amount', 'qty', 'quantity', 'rate', 'date',
    'item', 'particulars', 'mrp', 'balance', 'rs.', 'inr', '₹', 'payable',
    'discount', 'vendor', 'supplier', 'customer', 'payment', 'voucher', 'charges', 'round off'
}


def is_likely_invoice(raw_text: Optional[str]) -> bool:
    """Pre-AI filter to reject non-bill photos (faces, objects, rooms) before invoking Gemini."""
    if not raw_text:
        return False
    cleaned = raw_text.strip()
    if len(cleaned) < 20:
        return False
    lines = [l for l in cleaned.splitlines() if l.strip()]
    if len(lines) < 3:
        return False
    lower = cleaned.lower()
    if any(kw in lower for kw in STRONG_BILL_KEYWORDS):
        return True
    secondary_count = sum(1 for kw in SECONDARY_BILL_KEYWORDS if kw in lower)
    return secondary_count >= 2


class OCRExtractionResponse(BaseModel):
    """Response returned upon photo image upload and OCR scanning."""
    id: str
    filename: str
    file_hash_sha256: str
    image_url: str
    ocr_result: OCRResult
    extracted_data: InvoiceExtractedData
    line_count: int


def _user_upload_dir(user_id: str) -> Path:
    """Return isolated upload directory for a verified user."""
    settings.ensure_directories()
    safe_user = _SAFE_SEGMENT_RE.sub("_", user_id.strip())[:80] or "anonymous"
    user_dir = settings.DOCUMENT_ROOT / "uploads" / safe_user
    user_dir.mkdir(parents=True, exist_ok=True)
    return user_dir


async def _read_upload_bounded(file: UploadFile, max_bytes: int) -> bytes:
    """Read upload in chunks while enforcing a hard memory/size ceiling."""
    chunks: list[bytes] = []
    total = 0
    while True:
        chunk = await file.read(_READ_CHUNK_SIZE)
        if not chunk:
            break
        total += len(chunk)
        if total > max_bytes:
            raise HTTPException(
                status_code=status.HTTP_413_CONTENT_TOO_LARGE,
                detail="Uploaded file exceeds the maximum allowed size (10 MB).",
            )
        chunks.append(chunk)
    return b"".join(chunks)


@router.post("/ocr", response_model=OCRExtractionResponse, status_code=status.HTTP_201_CREATED)
async def upload_and_extract_ocr(
    file: UploadFile = File(...),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    """Upload photo bill/invoice and scan with OCR + Gemini Vision."""
    filename = file.filename or "invoice_photo.jpg"
    ext = Path(filename).suffix.lower()

    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file type '{ext}'. Allowed image photo formats: {', '.join(sorted(ALLOWED_EXTENSIONS))}",
        )

    content = await _read_upload_bounded(file, settings.MAX_UPLOAD_BYTES)
    if not content:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty.",
        )

    # Compute SHA-256 integrity hash per AGENTS.md Rule 80
    file_hash = hashlib.sha256(content).hexdigest()

    # Save original photo scoped strictly inside authenticated user's directory
    safe_name_tail = _SAFE_SEGMENT_RE.sub("_", Path(filename).name)[:80] or f"upload{ext}"
    safe_filename = f"{file_hash[:16]}_{safe_name_tail}"
    saved_path = _user_upload_dir(current_user.user_id) / safe_filename
    saved_path.write_bytes(content)

    # Execute OCR extraction
    ocr_adapter = get_ocr_service()
    try:
        ocr_result = ocr_adapter.extract_from_image(content)
    except Exception:
        logger.exception("OCR engine extraction failed for user=%s", current_user.user_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="OCR processing failed. Please try again with a clearer image.",
        )

    # Pre-AI Gate: Enforce text keyword filter when local OCR extracted text;
    # if server-side OCR is unavailable (MockOCRAdapter returning "" outside tests),
    # let Gemini Vision inspect and validate image_bytes directly.
    has_ocr_text = bool(ocr_result.raw_text and ocr_result.raw_text.strip())
    if (has_ocr_text or not isinstance(ocr_adapter, MockOCRAdapter)) and not is_likely_invoice(
        ocr_result.raw_text
    ):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="The scanned photo does not appear to be an invoice or receipt. Please capture a clear bill image.",
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

    if not extracted_data.supplier_name and not extracted_data.total_amount:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Could not detect invoice details or vendor in the image. Please upload a clear photo of a bill.",
        )

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
async def extract_from_raw_ocr(
    ocr_result: OCRResult,
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    """Directly run Gemini structured bill extraction on an existing OCR result payload."""
    if not is_likely_invoice(ocr_result.raw_text):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="The scanned photo does not appear to be an invoice or receipt. Please capture a clear bill image.",
        )
    extractor = get_extraction_service()
    return extractor.extract(ocr_result)


@router.get("/file/{filename}")
async def get_invoice_file(
    filename: str,
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    """Serve uploaded invoice photo image owned by the authenticated user."""
    user_dir = _user_upload_dir(current_user.user_id).resolve()
    safe_name = Path(filename).name
    if not safe_name or safe_name != filename:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File not found")

    file_path = (user_dir / safe_name).resolve()
    if not file_path.is_relative_to(user_dir) or not file_path.exists() or not file_path.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File not found")

    ext = file_path.suffix.lower()
    media_type = "image/jpeg"
    if ext == ".png":
        media_type = "image/png"
    elif ext == ".webp":
        media_type = "image/webp"
    elif ext == ".bmp":
        media_type = "image/bmp"

    return FileResponse(file_path, media_type=media_type)
