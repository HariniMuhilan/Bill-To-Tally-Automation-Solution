"""Tests for Invoices API endpoints."""

import io
from PIL import Image, ImageDraw
import pytest
from fastapi.testclient import TestClient
from backend.app.main import app

client = TestClient(app)


def test_api_health():
    """Verify system health endpoint."""
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["posting_enabled"] is False


def test_upload_ocr_endpoint_with_image():
    """Verify /api/invoices/ocr accepts photo image, performs OCR, and returns structured result."""
    # Create test image in memory
    img = Image.new("RGB", (300, 80), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw.text((10, 25), "TAX INVOICE 9988", fill=(0, 0, 0))

    img_bytes = io.BytesIO()
    img.save(img_bytes, format="PNG")
    img_bytes.seek(0)

    files = {"file": ("test_bill.png", img_bytes, "image/png")}
    response = client.post("/api/invoices/ocr", files=files)

    assert response.status_code == 201
    data = response.json()

    assert data["filename"] == "test_bill.png"
    assert "file_hash_sha256" in data
    assert len(data["file_hash_sha256"]) == 64  # SHA-256
    assert data["image_url"].startswith("/api/invoices/file/")
    assert data["line_count"] >= 1
    assert "ocr_result" in data
    assert "TAX" in data["ocr_result"]["raw_text"].upper() or "INVOICE" in data["ocr_result"]["raw_text"].upper()

    # Verify image serving endpoint
    img_res = client.get(data["image_url"])
    assert img_res.status_code == 200
    assert img_res.headers["content-type"] == "image/png"


def test_upload_ocr_endpoint_unsupported_format():
    """Verify non-image formats are rejected with 400 Bad Request."""
    dummy_file = io.BytesIO(b"fake text content")
    files = {"file": ("document.txt", dummy_file, "text/plain")}
    response = client.post("/api/invoices/ocr", files=files)

    assert response.status_code == 400
    assert "Unsupported file type" in response.json()["detail"]
