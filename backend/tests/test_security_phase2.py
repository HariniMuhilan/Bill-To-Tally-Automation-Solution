"""Phase 2 security, bottleneck, and production-hardening tests."""

import base64
import hashlib
import hmac
import io
import json
import time
from types import SimpleNamespace

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec
from fastapi.testclient import TestClient
from PIL import Image, ImageDraw
import pytest

from backend.app.core import auth
from backend.app.core.config import settings
from backend.app.main import create_app
from backend.app.schemas.invoice import OCRResult
from backend.app.services import extraction as extraction_module
from backend.app.services.extraction import GeminiExtractionService

_TEST_SECRET = "phase2-test-jwt-secret-min-32-chars!"


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _sign_hs256(claims: dict, secret: str = _TEST_SECRET, alg: str = "HS256") -> str:
    header = _b64url(json.dumps({"alg": alg, "typ": "JWT"}).encode("utf-8"))
    payload = _b64url(json.dumps(claims).encode("utf-8"))
    signing_input = f"{header}.{payload}".encode("ascii")
    if alg == "none":
        return f"{header}.{payload}."
    sig = _b64url(hmac.new(secret.encode("utf-8"), signing_input, hashlib.sha256).digest())
    return f"{header}.{payload}.{sig}"


def _valid_claims(sub: str = "user-alpha", offset: int = 300) -> dict:
    return {
        "sub": sub,
        "aud": "authenticated",
        "role": "authenticated",
        "exp": int(time.time()) + offset,
    }


def _png_bytes(label: str = "TAX INVOICE") -> bytes:
    img = Image.new("RGB", (450, 220), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw.text((20, 20), label, fill=(0, 0, 0))
    draw.text((20, 60), "GSTIN: 33AAAAA1234A1Z5", fill=(0, 0, 0))
    draw.text((20, 100), "Invoice No: INV-2026-100", fill=(0, 0, 0))
    draw.text((20, 140), "Total Amount: 1180.00", fill=(0, 0, 0))
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


def test_jwt_validation_rejects_missing_expired_wrong_secret_and_alg_none(monkeypatch):
    monkeypatch.setattr(settings, "AUTH_REQUIRED", True)
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", _TEST_SECRET)
    monkeypatch.setattr(settings, "SUPABASE_URL", "")
    client = TestClient(create_app())

    payload = {"raw_text": "TAX INVOICE\nGSTIN: 33AAAAA1234A1Z5\nTOTAL: 100", "lines": []}

    # 1. Missing Authorization header
    assert client.post("/api/invoices/extract-text", json=payload).status_code == 401
    assert client.get("/api/tally/health").status_code == 401

    # 2. alg=none attack
    alg_none = _sign_hs256(_valid_claims(), alg="none")
    assert client.post(
        "/api/invoices/extract-text",
        json=payload,
        headers={"Authorization": f"Bearer {alg_none}"},
    ).status_code == 401

    # 3. Wrong secret
    bad_sig = _sign_hs256(_valid_claims(), secret="wrong-secret")
    assert client.post(
        "/api/invoices/extract-text",
        json=payload,
        headers={"Authorization": f"Bearer {bad_sig}"},
    ).status_code == 401

    # 4. Expired token
    expired = _sign_hs256(_valid_claims(offset=-180))
    assert client.post(
        "/api/invoices/extract-text",
        json=payload,
        headers={"Authorization": f"Bearer {expired}"},
    ).status_code == 401

    # 5. Wrong audience
    wrong_aud = _sign_hs256({"sub": "u1", "aud": "anon", "exp": int(time.time()) + 300})
    assert client.post(
        "/api/invoices/extract-text",
        json=payload,
        headers={"Authorization": f"Bearer {wrong_aud}"},
    ).status_code == 401


def test_auth_fails_closed_when_unconfigured(monkeypatch):
    monkeypatch.setattr(settings, "AUTH_REQUIRED", True)
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", "")
    monkeypatch.setattr(settings, "SUPABASE_URL", "")
    client = TestClient(create_app())

    token = _sign_hs256(_valid_claims())
    res = client.get("/api/tally/health", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 503


def test_es256_jwks_verification(monkeypatch):
    """Verify modern Supabase ES256 JWKS token signature validation."""
    auth.clear_jwks_cache()
    private_key = ec.generate_private_key(ec.SECP256R1())
    pub_nums = private_key.public_key().public_numbers()
    jwk = {
        "kty": "EC",
        "crv": "P-256",
        "kid": "test-es256-kid",
        "x": _b64url(pub_nums.x.to_bytes(32, "big")),
        "y": _b64url(pub_nums.y.to_bytes(32, "big")),
    }

    monkeypatch.setattr(settings, "AUTH_REQUIRED", True)
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", "")
    monkeypatch.setattr(settings, "SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setattr(auth, "_fetch_jwks", lambda url, force_refresh=False: [jwk])

    header = _b64url(json.dumps({"alg": "ES256", "kid": "test-es256-kid", "typ": "JWT"}).encode())
    claims = {
        "sub": "user-es256",
        "aud": "authenticated",
        "iss": "https://example.supabase.co/auth/v1",
        "exp": int(time.time()) + 300,
    }
    payload = _b64url(json.dumps(claims).encode())
    signing_input = f"{header}.{payload}".encode("ascii")

    from cryptography.hazmat.primitives import hashes
    from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature

    der_sig = private_key.sign(signing_input, ec.ECDSA(hashes.SHA256()))
    r, s = decode_dss_signature(der_sig)
    raw_sig = r.to_bytes(32, "big") + s.to_bytes(32, "big")
    jwt_token = f"{header}.{payload}.{_b64url(raw_sig)}"

    client = TestClient(create_app())
    res = client.get("/api/tally/health", headers={"Authorization": f"Bearer {jwt_token}"})
    assert res.status_code == 200


def test_per_user_file_isolation_and_path_traversal(monkeypatch, tmp_path):
    """Ensure User B cannot read User A's uploaded invoice images or traverse paths."""
    monkeypatch.setattr(settings, "AUTH_REQUIRED", True)
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", _TEST_SECRET)
    monkeypatch.setattr(settings, "DOCUMENT_ROOT", tmp_path)

    client = TestClient(create_app())
    user_a_headers = {"Authorization": f"Bearer {_sign_hs256(_valid_claims('user-A'))}"}
    user_b_headers = {"Authorization": f"Bearer {_sign_hs256(_valid_claims('user-B'))}"}

    upload_res = client.post(
        "/api/invoices/ocr",
        files={"file": ("secret_bill.png", io.BytesIO(_png_bytes()), "image/png")},
        headers=user_a_headers,
    )
    assert upload_res.status_code == 201
    image_url = upload_res.json()["image_url"]

    # Owner can fetch their file
    assert client.get(image_url, headers=user_a_headers).status_code == 200
    # Unauthenticated caller rejected
    assert client.get(image_url).status_code == 401
    # User B cannot access User A's file
    assert client.get(image_url, headers=user_b_headers).status_code == 404
    # Traversal probe blocked
    assert client.get("/api/invoices/file/..%2F..%2F.env", headers=user_a_headers).status_code == 404


def test_oversized_upload_rejected_with_413(monkeypatch):
    """Ensure large uploads fail with 413 instead of causing server OOM."""
    monkeypatch.setattr(settings, "AUTH_REQUIRED", True)
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", _TEST_SECRET)
    monkeypatch.setattr(settings, "MAX_UPLOAD_BYTES", 1024)  # 1 KB limit for test

    client = TestClient(create_app())
    headers = {"Authorization": f"Bearer {_sign_hs256(_valid_claims('user-size'))}"}
    oversized = io.BytesIO(b"A" * 2048)

    res = client.post(
        "/api/invoices/ocr",
        files={"file": ("huge.png", oversized, "image/png")},
        headers=headers,
    )
    assert res.status_code == 413


def test_production_hardening_docs_cors_health_and_sanitized_errors(monkeypatch):
    """Verify production mode disables /docs, restricts CORS, trims health, and hides raw tracebacks."""
    monkeypatch.setattr(settings, "APP_ENV", "production")
    monkeypatch.setattr(settings, "ALLOWED_ORIGINS", "https://billbooks.example.com")
    monkeypatch.setattr(settings, "AUTH_REQUIRED", True)
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", _TEST_SECRET)

    prod_client = TestClient(create_app())

    # OpenAPI / Swagger disabled in production
    assert prod_client.get("/docs").status_code == 404
    assert prod_client.get("/redoc").status_code == 404
    assert prod_client.get("/openapi.json").status_code == 404

    # Health omits internal model/OCR metadata in production
    health = prod_client.get("/api/health").json()
    assert health == {"status": "healthy", "posting_enabled": False}

    # CORS allows explicit origin and denies evil origin
    ok_cors = prod_client.options(
        "/api/health",
        headers={
            "Origin": "https://billbooks.example.com",
            "Access-Control-Request-Method": "GET",
        },
    )
    assert ok_cors.headers.get("access-control-allow-origin") == "https://billbooks.example.com"

    evil_cors = prod_client.options(
        "/api/health",
        headers={
            "Origin": "https://evil-attacker.example",
            "Access-Control-Request-Method": "GET",
        },
    )
    assert "access-control-allow-origin" not in evil_cors.headers

    # Sanitized OCR exception (no raw exception string exposed)
    class ExplodingOcr:
        def extract_from_image(self, _):
            raise RuntimeError("INTERNAL_SECRET_DB_PATH=/var/lib/secret")

    import backend.app.api.routes.invoices as inv_route

    monkeypatch.setattr(inv_route, "get_ocr_service", lambda: ExplodingOcr())
    headers = {"Authorization": f"Bearer {_sign_hs256(_valid_claims('user-err'))}"}
    err_res = prod_client.post(
        "/api/invoices/ocr",
        files={"file": ("bill.png", io.BytesIO(_png_bytes()), "image/png")},
        headers=headers,
    )
    assert err_res.status_code == 500
    assert "INTERNAL_SECRET_DB_PATH" not in err_res.json()["detail"]


def test_multimodal_empty_text_cache_does_not_collide_across_different_images():
    """Verify two different images with empty raw_text do not share the same cache entry."""
    with extraction_module._cache_lock:
        extraction_module._extraction_cache.clear()

    service = GeminiExtractionService(api_key="")
    empty_ocr = OCRResult(raw_text="", lines=[], page_count=1, average_confidence=0.0)

    res1 = service.extract(empty_ocr, image_bytes=b"image-bytes-1")
    res2 = service.extract(empty_ocr, image_bytes=b"image-bytes-2")

    assert res1.raw_ocr_text == ""
    assert res2.raw_ocr_text == ""
    assert all(w.field_name != "gemini_cache" for w in res2.warnings)


def test_render_fallback_without_paddleocr_passes_image_to_vision_extractor(monkeypatch, tmp_path):
    """Verify web upload succeeds via multimodal extractor even when MockOCRAdapter yields empty raw_text."""
    monkeypatch.setattr(settings, "APP_ENV", "production")
    monkeypatch.setattr(settings, "AUTH_REQUIRED", True)
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", _TEST_SECRET)
    monkeypatch.setattr(settings, "DOCUMENT_ROOT", tmp_path)

    import backend.app.api.routes.invoices as inv_route
    from backend.app.schemas.invoice import InvoiceExtractedData
    from backend.app.services.ocr_service import MockOCRAdapter
    from decimal import Decimal

    class FakeVisionExtractor:
        def extract(self, ocr_result, image_bytes=None, mime_type="image/jpeg"):
            assert image_bytes is not None
            return InvoiceExtractedData(
                supplier_name="RAGA PVT LTD",
                invoice_number="SR2",
                total_amount=Decimal("811.00"),
                overall_confidence=0.95,
            )

    monkeypatch.setattr(inv_route, "get_ocr_service", lambda: MockOCRAdapter())
    monkeypatch.setattr(inv_route, "get_extraction_service", lambda: FakeVisionExtractor())

    client = TestClient(create_app())
    headers = {"Authorization": f"Bearer {_sign_hs256(_valid_claims('user-web'))}"}
    res = client.post(
        "/api/invoices/ocr",
        files={"file": ("web_bill.png", io.BytesIO(_png_bytes()), "image/png")},
        headers=headers,
    )
    assert res.status_code == 201
    assert res.json()["extracted_data"]["supplier_name"] == "RAGA PVT LTD"
