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

def test_draft_sheets_sync(client: TestClient, monkeypatch):
    user = make_user()
    other_user = make_user("usr-client-02", "other@shop.com")
    app = client.app
    app.dependency_overrides[get_current_user] = lambda: user

    # 1. Batch object format {"sheets": [...]}
    sheet_payload = {
        "sheets": [
            {
                "sheet_id": "XL-2026-001",
                "sheet_name": "November_Wholesale_Bills.xlsx",
                "rows_json": [{"id": "INV-1", "supplierRaw": "Raga Hardware", "grandTotal": 1499.0}],
            }
        ]
    }
    put_resp = client.put("/api/me/draft-sheets", json=sheet_payload)
    assert put_resp.status_code == 200
    assert len(put_resp.json()) == 1
    assert put_resp.json()[0]["sheet_id"] == "XL-2026-001"

    # 2. Legacy raw list format [...] updating same sheet_id with 2nd bill (upsert, no duplicate)
    raw_list_payload = [
        {
            "sheet_id": "XL-2026-001",
            "sheet_name": "November_Wholesale_Bills.xlsx",
            "rows_json": [
                {"id": "INV-1", "supplierRaw": "Raga Hardware", "grandTotal": 1499.0},
                {"id": "INV-2", "supplierRaw": "Kothari Steel", "grandTotal": 2500.0},
            ],
        },
        {
            "sheet_id": "XL-2026-002",
            "sheet_name": "December_Bills.xlsx",
            "rows_json": [{"id": "INV-3", "supplierRaw": "Bafna Electricals", "grandTotal": 800.0}],
        },
    ]
    list_resp = client.put("/api/me/draft-sheets", json=raw_list_payload)
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 2

    # 3. Single item object format {...}
    single_resp = client.put(
        "/api/me/draft-sheets",
        json={
            "sheet_id": "XL-2026-003",
            "sheet_name": "Single.xlsx",
            "rows_json": [{"id": "INV-4", "grandTotal": 100.0}],
        },
    )
    assert single_resp.status_code == 200

    # Verify GET returns 3 distinct sheets and XL-2026-001 has both bills
    get_resp = client.get("/api/me/draft-sheets")
    assert get_resp.status_code == 200
    by_id = {item["sheet_id"]: item for item in get_resp.json()}
    assert len(by_id) == 3
    assert len(by_id["XL-2026-001"]["rows_json"]) == 2

    # 4. Cross-user isolation
    app.dependency_overrides[get_current_user] = lambda: other_user
    other_get = client.get("/api/me/draft-sheets")
    assert other_get.status_code == 200
    assert other_get.json() == []

    # 5. Replace=True prunes deleted sheets cleanly
    app.dependency_overrides[get_current_user] = lambda: user
    prune_resp = client.put(
        "/api/me/draft-sheets",
        json={"sheets": [raw_list_payload[0]], "replace": True},
    )
    assert prune_resp.status_code == 200
    after_prune = client.get("/api/me/draft-sheets").json()
    assert [s["sheet_id"] for s in after_prune] == ["XL-2026-001"]

    # Empty replace=True clears all sheets
    clear_resp = client.put("/api/me/draft-sheets", json={"sheets": [], "replace": True})
    assert clear_resp.status_code == 200
    assert client.get("/api/me/draft-sheets").json() == []

    # 6. Live PostgREST mode sends single batch POST with ?on_conflict=user_id,sheet_id
    admin_client = get_supabase_admin()
    captured_calls = []

    class FakeResp:
        def __init__(self, status_code=200, data=None):
            self.status_code = status_code
            self._data = data if data is not None else []
            self.text = "ok"

        def json(self):
            return self._data

    class FakeHttpxClient:
        def __init__(self, *args, **kwargs):
            pass

        def __enter__(self):
            return self

        def __exit__(self, *args):
            return False

        def post(self, url, json=None, headers=None):
            captured_calls.append(("POST", url, json, headers))
            return FakeResp(201, json)

        def delete(self, url, headers=None):
            captured_calls.append(("DELETE", url, None, headers))
            return FakeResp(204, [])

    monkeypatch.setattr(admin_client, "supabase_url", "https://example.supabase.co")
    monkeypatch.setattr(admin_client, "service_role_key", "test-service-key")
    monkeypatch.setattr(admin_client, "_is_live", True)
    monkeypatch.setattr("backend.app.services.supabase_admin.httpx.Client", FakeHttpxClient)

    live_resp = client.put(
        "/api/me/draft-sheets",
        json={"sheets": raw_list_payload, "replace": True},
    )
    assert live_resp.status_code == 200
    assert len(captured_calls) == 2  # 1 batch POST + 1 prune DELETE
    post_method, post_url, post_body, post_headers = captured_calls[0]
    assert post_method == "POST"
    assert post_url == "https://example.supabase.co/rest/v1/user_draft_sheets?on_conflict=user_id,sheet_id"
    assert len(post_body) == 2
    assert post_headers["Prefer"] == "resolution=merge-duplicates,return=representation"
    del_method, del_url, _, _ = captured_calls[1]
    assert del_method == "DELETE"
    assert "sheet_id=not.in." in del_url

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


def test_access_request_otp_enforcement_and_duplicate_block(client: TestClient, monkeypatch):
    """Verify duplicate pending check, live OTP JWT enforcement, and provisioning pre-created OTP users."""
    import base64
    import hashlib
    import hmac
    import json
    import time

    secret = "test-otp-enforcement-secret-32chars!!"
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", secret)

    def sign_jwt(email: str, sub: str = "otp-user-1") -> str:
        def b64(d: bytes) -> str:
            return base64.urlsafe_b64encode(d).rstrip(b"=").decode("ascii")

        h = b64(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
        p = b64(
            json.dumps({
                "sub": sub,
                "email": email,
                "aud": "authenticated",
                "role": "authenticated",
                "exp": int(time.time()) + 300,
            }).encode()
        )
        sig = b64(hmac.new(secret.encode(), f"{h}.{p}".encode(), hashlib.sha256).digest())
        return f"{h}.{p}.{sig}"

    payload = {
        "full_name": "Arjun S",
        "business_name": "Arjun Traders",
        "email": "arjun@traders.in",
        "phone": "+91 98401 23456",
    }

    # 1. Mismatched JWT email is rejected with 403
    wrong_jwt = sign_jwt("other@attacker.com")
    mismatch = client.post(
        "/api/access-requests",
        json=payload,
        headers={"Authorization": f"Bearer {wrong_jwt}"},
    )
    assert mismatch.status_code == 403

    # 2. Matching OTP JWT succeeds with 201
    good_jwt = sign_jwt("arjun@traders.in")
    ok_resp = client.post(
        "/api/access-requests",
        json=payload,
        headers={"Authorization": f"Bearer {good_jwt}"},
    )
    assert ok_resp.status_code == 201

    # 3. Duplicate pending request is rejected with 409
    dup_resp = client.post(
        "/api/access-requests",
        json=payload,
        headers={"Authorization": f"Bearer {good_jwt}"},
    )
    assert dup_resp.status_code == 409

    # 4. In live mode, missing Bearer token on /access-requests -> 401, and unprovisioned /session/claim -> 403
    admin_client = get_supabase_admin()
    monkeypatch.setattr(admin_client, "_is_live", True)

    no_auth = client.post("/api/access-requests", json={**payload, "email": "fresh@shop.in"})
    assert no_auth.status_code == 401

    app = client.app
    app.dependency_overrides[get_current_user] = lambda: make_user("unprov-1", "unprov@shop.in")
    monkeypatch.setattr(admin_client, "get_user_subscription", lambda uid: None)
    unprov_claim = client.post("/api/me/session/claim", json={"device_label": "Pixel 8"})
    assert unprov_claim.status_code == 403
    app.dependency_overrides.clear()

    # 5. Provisioning an email that already exists as an unprovisioned OTP user in mock store succeeds
    monkeypatch.setattr(admin_client, "_is_live", False)
    admin_client._mock_users["otp-user-1"] = {
        "id": "otp-user-1",
        "email": "arjun@traders.in",
        "user_metadata": {},
    }
    app.dependency_overrides[get_current_user] = lambda: make_admin()
    prov = client.post(
        "/api/admin/users/provision",
        json={
            "request_id": ok_resp.json()["request_id"],
            "email": "arjun@traders.in",
            "password": "TempPassword@2026",
            "full_name": "Arjun S",
            "business_name": "Arjun Traders",
            "phone": "+91 98401 23456",
        },
    )
    assert prov.status_code == 201
    assert prov.json()["user_id"] == "otp-user-1"
    app.dependency_overrides.clear()
