"""Tests for Phase 2: Admin Provisioning, Single-Device Lock, Subscription Guard, and Excel Sync."""

from datetime import date, datetime, timedelta, timezone
from pathlib import Path
import pytest
from fastapi.testclient import TestClient

from backend.app.core.auth import AuthenticatedUser, get_admin_user, get_current_user
from backend.app.core.config import settings
from backend.app.main import create_app
from backend.app.schemas.invoice import InvoiceExtractedData
from backend.app.services.supabase_admin import get_supabase_admin, reset_supabase_admin_for_tests


@pytest.fixture(autouse=True)
def setup_test_env(tmp_path: Path):
    """Isolate storage and reset in-memory admin client before each test."""
    original_doc_root = settings.DOCUMENT_ROOT
    original_key = settings.SUPABASE_SERVICE_ROLE_KEY
    settings.DOCUMENT_ROOT = tmp_path
    settings.AUTH_REQUIRED = True
    settings.ADMIN_EMAILS = "admin@billbooks.app,superadmin@ashantech.com"
    settings.SUPABASE_SERVICE_ROLE_KEY = ""
    reset_supabase_admin_for_tests()
    yield
    settings.DOCUMENT_ROOT = original_doc_root
    settings.SUPABASE_SERVICE_ROLE_KEY = original_key


@pytest.fixture
def client():
    app = create_app()
    return TestClient(app)


def make_user(user_id: str = "usr-client-01", email: str = "client@parrys.com", role: str = "authenticated") -> AuthenticatedUser:
    return AuthenticatedUser(
        user_id=user_id,
        email=email,
        role=role,
        claims={"sub": user_id, "email": email, "role": role},
    )


def make_admin(user_id: str = "usr-admin-01", email: str = "admin@billbooks.app") -> AuthenticatedUser:
    return AuthenticatedUser(
        user_id=user_id,
        email=email,
        role="authenticated",
        claims={"sub": user_id, "email": email, "role": "authenticated"},
    )


# =============================================================================
# 1. Public Endpoints
# =============================================================================

def test_ping_endpoint(client: TestClient):
    resp = client.get("/api/ping")
    assert resp.status_code == 200
    data = resp.json()
    assert data["ok"] is True
    assert "timestamp" in data


def test_access_request_flow(client: TestClient):
    payload = {
        "full_name": "Ramesh Kumar",
        "business_name": "Raga Electricals",
        "email": "ramesh.raga@gmail.com",
        "phone": "+91 98401 23456",
        "notes": "Looking for thermal bill to Excel automation",
    }
    resp = client.post("/api/access-requests", json=payload)
    assert resp.status_code == 201
    data = resp.json()
    assert data["ok"] is True
    assert "request_id" in data


# =============================================================================
# 2. Single-Device Session Claim & Conflict
# =============================================================================

def test_single_device_claim_and_conflict(client: TestClient):
    user = make_user()
    app = client.app
    app.dependency_overrides[get_current_user] = lambda: user

    # 1. Device A claims session
    resp1 = client.post(
        "/api/me/session/claim",
        json={"device_label": "Pixel 7 Pro (Android 14)"},
    )
    assert resp1.status_code == 200
    session_a = resp1.json()["session_id"]
    assert session_a is not None

    # 2. Device B attempts to claim without force -> 409 Conflict
    resp2 = client.post(
        "/api/me/session/claim",
        json={"device_label": "Samsung Galaxy S24"},
    )
    assert resp2.status_code == 409
    assert "Pixel 7 Pro" in resp2.json()["detail"]

    # 3. Device B claims with force=True -> succeeds, overwriting session
    resp3 = client.post(
        "/api/me/session/claim",
        json={"device_label": "Samsung Galaxy S24", "force": True},
    )
    assert resp3.status_code == 200
    session_b = resp3.json()["session_id"]
    assert session_b != session_a

    # 4. Release session
    rel = client.post("/api/me/session/release")
    assert rel.status_code == 200

    app.dependency_overrides.clear()


# =============================================================================
# 3. Subscription Gating (Scanning vs View-Only Expiry)
# =============================================================================

def test_subscription_expiry_gating(client: TestClient, monkeypatch):
    user = make_user()
    app = client.app
    app.dependency_overrides[get_current_user] = lambda: user
    admin_client = get_supabase_admin()

    class DummyExtractor:
        def extract(self, *args, **kwargs):
            return InvoiceExtractedData(
                supplier_name="Raga Hardware Pvt Ltd",
                total_amount="1500.00",
                invoice_number="INV-2026-991",
            )

    monkeypatch.setattr("backend.app.api.routes.invoices.get_extraction_service", lambda: DummyExtractor())

    # Provision user with an EXPIRED subscription
    yesterday = date.today() - timedelta(days=1)
    last_month = date.today() - timedelta(days=31)
    admin_client.upsert_user_subscription({
        "user_id": user.user_id,
        "email": user.email,
        "full_name": "Ramesh Kumar",
        "status": "active",
        "subscription_start": str(last_month),
        "subscription_end": str(yesterday),  # expired!
        "active_session_id": "test-session-uuid",
        "active_device_label": "Test Phone",
    })

    # Status check indicates scan not allowed
    status_resp = client.get("/api/me/status")
    assert status_resp.status_code == 200
    assert status_resp.json()["is_scan_allowed"] is False

    # Attempting to scan/extract OCR is rejected with 403 Forbidden
    ocr_payload = {
        "raw_text": "TAX INVOICE\nRAGA ELECTRICALS PVT LTD\nTOTAL AMOUNT: Rs. 1500\nGSTIN: 33AAAAA0000A1Z5",
        "average_confidence": 0.95,
        "lines": [
            {"text": "TAX INVOICE", "confidence": 0.95},
            {"text": "RAGA ELECTRICALS PVT LTD", "confidence": 0.95},
            {"text": "TOTAL AMOUNT: Rs. 1500", "confidence": 0.95},
        ],
    }
    scan_resp = client.post(
        "/api/invoices/extract-text",
        json=ocr_payload,
        headers={"X-Device-Session-Id": "test-session-uuid"},
    )
    assert scan_resp.status_code == 403
    assert "Subscription expired or blocked" in scan_resp.json()["detail"]

    # BUT user can still access draft sheets (view-only mode!)
    sheets_resp = client.get("/api/me/draft-sheets")
    assert sheets_resp.status_code == 200

    # Now update subscription to be ACTIVE
    tomorrow = date.today() + timedelta(days=30)
    admin_client.update_user_subscription(user.user_id, {
        "subscription_end": str(tomorrow),
    })

    # Scanning is now permitted
    scan_ok = client.post(
        "/api/invoices/extract-text",
        json=ocr_payload,
        headers={"X-Device-Session-Id": "test-session-uuid"},
    )
    assert scan_ok.status_code == 200

    app.dependency_overrides.clear()


# =============================================================================
# 4. Excel Draft Sheets Sync
# =============================================================================

def test_draft_sheets_sync(client: TestClient):
    user = make_user()
    app = client.app
    app.dependency_overrides[get_current_user] = lambda: user

    sheet_payload = {
        "sheets": [
            {
                "sheet_id": "XL-2026-001",
                "sheet_name": "November_Wholesale_Bills.xlsx",
                "rows_json": [{"supplier": "Raga Hardware", "amount": 1499.0}],
            }
        ]
    }

    # PUT draft sheets
    put_resp = client.put("/api/me/draft-sheets", json=sheet_payload)
    assert put_resp.status_code == 200
    data = put_resp.json()
    assert len(data) == 1
    assert data[0]["sheet_id"] == "XL-2026-001"

    # GET draft sheets
    get_resp = client.get("/api/me/draft-sheets")
    assert get_resp.status_code == 200
    fetched = get_resp.json()
    assert len(fetched) == 1
    assert fetched[0]["sheet_name"] == "November_Wholesale_Bills.xlsx"

    app.dependency_overrides.clear()


# =============================================================================
# 5. Admin Authorization & User Provisioning Lifecycle
# =============================================================================

def test_admin_endpoints_require_admin_privileges(client: TestClient):
    # Regular user attempting admin endpoint -> 403 Forbidden
    reg_user = make_user("reg-01", "normal@shop.com")
    app = client.app
    app.dependency_overrides[get_current_user] = lambda: reg_user

    resp = client.get("/api/admin/users")
    assert resp.status_code == 403
    assert "Administrative privileges required" in resp.json()["detail"]

    # Authorized admin -> 200 OK
    admin_user = make_admin()
    app.dependency_overrides[get_current_user] = lambda: admin_user

    admin_resp = client.get("/api/admin/users")
    assert admin_resp.status_code == 200

    app.dependency_overrides.clear()


def test_admin_provision_cancel_unblock_lifecycle(client: TestClient):
    admin_user = make_admin()
    app = client.app
    app.dependency_overrides[get_current_user] = lambda: admin_user

    # 1. Provision user
    prov_payload = {
        "email": "mahesh.kothari@gmail.com",
        "password": "SecurePassword@2026",
        "full_name": "Mahesh Kothari",
        "business_name": "Kothari Steel & Hardware",
        "phone": "+91 98840 55123",
        "amount_paid_inr": 2499.0,
        "payment_notes": "Paid via UPI ref #9810294812",
    }
    prov_resp = client.post("/api/admin/users/provision", json=prov_payload)
    assert prov_resp.status_code == 201
    created = prov_resp.json()
    new_user_id = created["user_id"]
    assert created["temporary_password"] == "SecurePassword@2026"

    # 2. Cancel user subscription
    cancel_resp = client.post(f"/api/admin/users/{new_user_id}/cancel")
    assert cancel_resp.status_code == 200
    assert cancel_resp.json()["subscription"]["status"] == "cancelled"

    # 3. Unblock / renew user subscription
    unblock_payload = {
        "amount_paid_inr": 2499.0,
        "payment_notes": "Renewed via NEFT",
    }
    unblock_resp = client.post(f"/api/admin/users/{new_user_id}/unblock", json=unblock_payload)
    assert unblock_resp.status_code == 200
    assert unblock_resp.json()["subscription"]["status"] == "active"

    # 4. Reset device
    reset_resp = client.post(f"/api/admin/users/{new_user_id}/reset-device")
    assert reset_resp.status_code == 200
    assert reset_resp.json()["subscription"]["active_session_id"] is None

    # 5. Delete user
    del_resp = client.delete(f"/api/admin/users/{new_user_id}")
    assert del_resp.status_code == 200

    app.dependency_overrides.clear()
