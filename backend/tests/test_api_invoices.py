"""Tests for Invoices API endpoints."""

import base64
import hashlib
import hmac
import io
import json
import time
from PIL import Image, ImageDraw
import pytest
from fastapi.testclient import TestClient

from backend.app.core.config import settings
from backend.app.main import app

client = TestClient(app)
_TEST_SECRET = "unit-test-supabase-jwt-secret-key"


def _make_hs256_token(sub: str = "user-test-01", secret: str = _TEST_SECRET, exp_offset: int = 300) -> str:
    header = base64.urlsafe_b64encode(json.dumps({"alg": "HS256", "typ": "JWT"}).encode()).rstrip(b"=")
    payload = base64.urlsafe_b64encode(
        json.dumps({"sub": sub, "aud": "authenticated", "exp": int(time.time()) + exp_offset}).encode()
    ).rstrip(b"=")
    signing_input = header + b"." + payload
    sig = base64.urlsafe_b64encode(
        hmac.new(secret.encode("utf-8"), signing_input, hashlib.sha256).digest()
    ).rstrip(b"=")
    return (signing_input + b"." + sig).decode("ascii")


def test_api_health():
    """Verify system health endpoint."""
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["posting_enabled"] is False


def test_upload_ocr_requires_authentication():
    """Verify unauthenticated OCR upload fails closed with 401."""
    img_bytes = io.BytesIO(b"not-checked-before-auth")
    files = {"file": ("test_bill.png", img_bytes, "image/png")}
    response = client.post("/api/invoices/ocr", files=files)
    assert response.status_code == 401


def test_upload_ocr_endpoint_with_image(monkeypatch):
    """Verify /api/invoices/ocr accepts authenticated photo upload and isolates file access."""
    monkeypatch.setattr(settings, "AUTH_REQUIRED", True)
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", _TEST_SECRET)
    headers = {"Authorization": f"Bearer {_make_hs256_token('user-test-01')}"}

    img = Image.new("RGB", (450, 220), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw.text((20, 20), "TAX INVOICE", fill=(0, 0, 0))
    draw.text((20, 60), "GSTIN: 33AAAAA1234A1Z5", fill=(0, 0, 0))
    draw.text((20, 100), "Invoice No: INV-9988", fill=(0, 0, 0))
    draw.text((20, 140), "Total Amount: 1180.00", fill=(0, 0, 0))

    img_bytes = io.BytesIO()
    img.save(img_bytes, format="PNG")
    img_bytes.seek(0)

    files = {"file": ("test_bill.png", img_bytes, "image/png")}
    response = client.post("/api/invoices/ocr", files=files, headers=headers)

    assert response.status_code == 201
    data = response.json()

    assert data["filename"] == "test_bill.png"
    assert "file_hash_sha256" in data
    assert len(data["file_hash_sha256"]) == 64  # SHA-256
    assert data["image_url"].startswith("/api/invoices/file/")
    assert data["line_count"] >= 1
    assert "ocr_result" in data
    assert "TAX" in data["ocr_result"]["raw_text"].upper() or "INVOICE" in data["ocr_result"]["raw_text"].upper()

    # Verify authenticated image serving endpoint succeeds for owner
    img_res = client.get(data["image_url"], headers=headers)
    assert img_res.status_code == 200
    assert img_res.headers["content-type"] == "image/png"


def test_upload_ocr_endpoint_unsupported_format(monkeypatch):
    """Verify non-image formats are rejected with 400 Bad Request for authenticated requests."""
    monkeypatch.setattr(settings, "AUTH_REQUIRED", True)
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", _TEST_SECRET)
    headers = {"Authorization": f"Bearer {_make_hs256_token('user-test-01')}"}

    dummy_file = io.BytesIO(b"fake text content")
    files = {"file": ("document.txt", dummy_file, "text/plain")}
    response = client.post("/api/invoices/ocr", files=files, headers=headers)

    assert response.status_code == 400
    assert "Unsupported file type" in response.json()["detail"]
