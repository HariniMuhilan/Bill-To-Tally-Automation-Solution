"""Supabase Admin Client for B2B Subscription & Auth Provisioning.

Uses httpx (already in requirements.txt) to communicate securely with:
- Supabase GoTrue Admin API (/auth/v1/admin/users)
- Supabase PostgREST API (/rest/v1/*) using the service_role key.
Includes an in-memory local fallback store when service_role key is unset or in local dev/testing.
"""

from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
import logging
from typing import Any, Dict, List, Optional
import uuid
from urllib.parse import quote
import httpx

try:
    from backend.app.core.config import settings
except (ImportError, ValueError):
    try:
        from app.core.config import settings
    except (ImportError, ValueError):
        # pyrefly: ignore[missing-import]
        from ..core.config import settings

logger = logging.getLogger(__name__)


class SupabaseAdminClient:
    """Admin-level client interacting with Supabase Auth and Postgres via service_role key."""

    def __init__(
        self,
        supabase_url: Optional[str] = None,
        service_role_key: Optional[str] = None,
        timeout: float = 8.0,
    ) -> None:
        self.supabase_url = (supabase_url or settings.SUPABASE_URL).rstrip("/")
        self.service_role_key = (service_role_key or settings.SUPABASE_SERVICE_ROLE_KEY).strip()
        self.timeout = timeout
        self._is_live = bool(self.supabase_url and self.service_role_key)

        # In-memory mock store for tests / offline development
        self._mock_users: Dict[str, Dict[str, Any]] = {}
        self._mock_access_requests: Dict[str, Dict[str, Any]] = {}
        self._mock_subscriptions: Dict[str, Dict[str, Any]] = {}
        self._mock_draft_sheets: Dict[str, Dict[str, Any]] = {}  # key: f"{user_id}:{sheet_id}"
        self._mock_deletion_requests: Dict[str, Dict[str, Any]] = {}

    @property
    def is_live(self) -> bool:
        """True when Supabase URL and service_role key are configured."""
        return self._is_live

    def _headers(self, prefer: Optional[str] = None) -> Dict[str, str]:
        headers = {
            "apikey": self.service_role_key,
            "Authorization": f"Bearer {self.service_role_key}",
            "Content-Type": "application/json",
        }
        if prefer:
            headers["Prefer"] = prefer
        return headers

    # =========================================================================
    # 1. Supabase Auth Admin (/auth/v1/admin/users)
    # =========================================================================

    def find_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Look up a Supabase Auth user by normalized email."""
        clean_email = email.strip().lower()
        if not self.is_live:
            for user in self._mock_users.values():
                if (user.get("email") or "").strip().lower() == clean_email:
                    return user
            return None

        with httpx.Client(timeout=self.timeout) as client:
            for page in range(1, 21):
                url = f"{self.supabase_url}/auth/v1/admin/users?page={page}&per_page=100"
                resp = client.get(url, headers=self._headers())
                if resp.status_code >= 400:
                    logger.error("Supabase Admin list users failed: %s %s", resp.status_code, resp.text)
                    break
                data = resp.json()
                users = data.get("users") if isinstance(data, dict) else data
                if not isinstance(users, list) or not users:
                    break
                for u in users:
                    if (u.get("email") or "").strip().lower() == clean_email:
                        return u
                if len(users) < 100:
                    break
        return None

    def create_user(
        self,
        email: str,
        password: str,
        full_name: str = "",
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Provision a new user directly in Supabase Auth (or finalize an OTP-verified unprovisioned user)."""
        clean_email = email.strip().lower()
        user_metadata = {"full_name": full_name}
        if metadata:
            user_metadata.update(metadata)

        if not self.is_live:
            for existing in self._mock_users.values():
                if (existing.get("email") or "").strip().lower() == clean_email:
                    if self.get_user_subscription(str(existing["id"])):
                        raise RuntimeError("A subscriber account with this email already exists.")
                    existing["user_metadata"] = user_metadata
                    return existing
            user_id = str(uuid.uuid4())
            user_record = {
                "id": user_id,
                "email": clean_email,
                "created_at": datetime.now(timezone.utc).isoformat(),
                "user_metadata": user_metadata,
            }
            self._mock_users[user_id] = user_record
            return user_record

        url = f"{self.supabase_url}/auth/v1/admin/users"
        payload = {
            "email": clean_email,
            "password": password,
            "email_confirm": True,
            "user_metadata": user_metadata,
        }

        with httpx.Client(timeout=self.timeout) as client:
            resp = client.post(url, json=payload, headers=self._headers())
            if resp.status_code < 400:
                return resp.json()

            err_text = resp.text.lower()
            if resp.status_code in (400, 422) and ("already" in err_text or "exists" in err_text):
                existing = self.find_user_by_email(clean_email)
                if existing and existing.get("id"):
                    existing_id = str(existing["id"])
                    if self.get_user_subscription(existing_id):
                        raise RuntimeError("A subscriber account with this email already exists.")
                    update_url = f"{self.supabase_url}/auth/v1/admin/users/{existing_id}"
                    update_resp = client.put(
                        update_url,
                        json={
                            "password": password,
                            "email_confirm": True,
                            "user_metadata": user_metadata,
                        },
                        headers=self._headers(),
                    )
                    if update_resp.status_code < 400:
                        return update_resp.json()
                    logger.error("Supabase Admin update_user failed: %s %s", update_resp.status_code, update_resp.text)
                    raise RuntimeError(f"Failed to provision existing user in Supabase Auth: {update_resp.text}")

            logger.error("Supabase Admin create_user failed: %s %s", resp.status_code, resp.text)
            raise RuntimeError(f"Failed to create user in Supabase Auth: {resp.text}")

    def delete_user(self, user_id: str) -> bool:
        """Permanently delete a user from Supabase Auth (triggers Postgres cascade on user_subscriptions)."""
        if not self.is_live:
            self._mock_users.pop(user_id, None)
            self._mock_subscriptions.pop(user_id, None)
            keys_to_del = [k for k in self._mock_draft_sheets if k.startswith(f"{user_id}:")]
            for k in keys_to_del:
                self._mock_draft_sheets.pop(k, None)
            return True

        url = f"{self.supabase_url}/auth/v1/admin/users/{user_id}"
        with httpx.Client(timeout=self.timeout) as client:
            resp = client.delete(url, headers=self._headers())
            if resp.status_code >= 400:
                logger.error("Supabase Admin delete_user failed: %s %s", resp.status_code, resp.text)
                raise RuntimeError(f"Failed to delete user in Supabase Auth: {resp.text}")
            return True

    # =========================================================================
    # 2. Access Requests (/rest/v1/access_requests)
    # =========================================================================

    def has_pending_access_request(self, email: str) -> bool:
        """Return True if a pending access request already exists for this email."""
        clean_email = email.strip().lower()
        if not self.is_live:
            return any(
                (r.get("email") or "").strip().lower() == clean_email and r.get("status") == "pending"
                for r in self._mock_access_requests.values()
            )

        url = (
            f"{self.supabase_url}/rest/v1/access_requests"
            f"?email=eq.{quote(clean_email, safe='')}&status=eq.pending&select=id&limit=1"
        )
        with httpx.Client(timeout=self.timeout) as client:
            resp = client.get(url, headers=self._headers())
            if resp.status_code >= 400:
                logger.error("has_pending_access_request failed: %s %s", resp.status_code, resp.text)
                return False
            items = resp.json()
            return isinstance(items, list) and len(items) > 0

    def create_access_request(
        self,
        full_name: str,
        business_name: str,
        email: str,
        phone: str,
        notes: str = "",
    ) -> Dict[str, Any]:
        """Insert a client access request."""
        clean_email = email.strip().lower()
        now_str = datetime.now(timezone.utc).isoformat()

        if not self.is_live:
            req_id = str(uuid.uuid4())
            record = {
                "id": req_id,
                "full_name": full_name.strip(),
                "business_name": business_name.strip(),
                "email": clean_email,
                "phone": phone.strip(),
                "notes": notes.strip(),
                "status": "pending",
                "created_at": now_str,
            }
            self._mock_access_requests[req_id] = record
            return record

        url = f"{self.supabase_url}/rest/v1/access_requests"
        payload = {
            "full_name": full_name.strip(),
            "business_name": business_name.strip(),
            "email": clean_email,
            "phone": phone.strip(),
            "notes": notes.strip(),
            "status": "pending",
        }
        with httpx.Client(timeout=self.timeout) as client:
            resp = client.post(url, json=payload, headers=self._headers(prefer="return=representation"))
            if resp.status_code >= 400:
                logger.error("Failed to insert access request: %s %s", resp.status_code, resp.text)
                raise RuntimeError(f"Database error inserting access request: {resp.text}")
            results = resp.json()
            return results[0] if isinstance(results, list) and results else results

    def list_access_requests(self, status_filter: Optional[str] = None) -> List[Dict[str, Any]]:
        """List onboarding requests ordered by created_at desc."""
        if not self.is_live:
            items = list(self._mock_access_requests.values())
            if status_filter:
                items = [i for i in items if i.get("status") == status_filter]
            return sorted(items, key=lambda x: x.get("created_at", ""), reverse=True)

        url = f"{self.supabase_url}/rest/v1/access_requests?select=*&order=created_at.desc"
        if status_filter:
            url += f"&status=eq.{status_filter}"

        with httpx.Client(timeout=self.timeout) as client:
            resp = client.get(url, headers=self._headers())
            if resp.status_code >= 400:
                raise RuntimeError(f"Failed to query access requests: {resp.text}")
            return resp.json()

    def update_access_request_status(self, request_id: str, new_status: str) -> Optional[Dict[str, Any]]:
        """Update request status ('approved' | 'rejected')."""
        if not self.is_live:
            req = self._mock_access_requests.get(request_id)
            if req:
                req["status"] = new_status
            return req

        url = f"{self.supabase_url}/rest/v1/access_requests?id=eq.{request_id}"
        payload = {"status": new_status}
        with httpx.Client(timeout=self.timeout) as client:
            resp = client.patch(url, json=payload, headers=self._headers(prefer="return=representation"))
            if resp.status_code >= 400:
                raise RuntimeError(f"Failed to update access request status: {resp.text}")
            items = resp.json()
            return items[0] if isinstance(items, list) and items else None

    # =========================================================================
    # 3. User Subscriptions (/rest/v1/user_subscriptions)
    # =========================================================================

    def get_user_subscription(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Retrieve user subscription record."""
        if not self.is_live:
            return self._mock_subscriptions.get(user_id)

        url = f"{self.supabase_url}/rest/v1/user_subscriptions?user_id=eq.{user_id}&select=*"
        with httpx.Client(timeout=self.timeout) as client:
            resp = client.get(url, headers=self._headers())
            if resp.status_code >= 400:
                logger.error("get_user_subscription failed: %s %s", resp.status_code, resp.text)
                return None
            items = resp.json()
            return items[0] if isinstance(items, list) and items else None

    def upsert_user_subscription(self, subscription_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create or update a subscription record."""
        user_id = str(subscription_data["user_id"])
        now_str = datetime.now(timezone.utc).isoformat()
        clean = dict(subscription_data)
        clean["updated_at"] = now_str
        if "created_at" not in clean:
            clean["created_at"] = now_str

        if not self.is_live:
            self._mock_subscriptions[user_id] = clean
            return clean

        url = f"{self.supabase_url}/rest/v1/user_subscriptions"
        with httpx.Client(timeout=self.timeout) as client:
            resp = client.post(
                url,
                json=clean,
                headers=self._headers(prefer="resolution=merge-duplicates,return=representation"),
            )
            if resp.status_code >= 400:
                logger.error("upsert_user_subscription failed: %s %s", resp.status_code, resp.text)
                raise RuntimeError(f"Database error saving subscription: {resp.text}")
            items = resp.json()
            return items[0] if isinstance(items, list) and items else items

    def update_user_subscription(self, user_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Patch specific fields in user_subscriptions."""
        now_str = datetime.now(timezone.utc).isoformat()
        clean_updates = dict(updates)
        clean_updates["updated_at"] = now_str

        if not self.is_live:
            sub = self._mock_subscriptions.get(user_id)
            if not sub:
                return None
            sub.update(clean_updates)
            return sub

        url = f"{self.supabase_url}/rest/v1/user_subscriptions?user_id=eq.{user_id}"
        with httpx.Client(timeout=self.timeout) as client:
            resp = client.patch(
                url,
                json=clean_updates,
                headers=self._headers(prefer="return=representation"),
            )
            if resp.status_code >= 400:
                logger.error("update_user_subscription failed: %s %s", resp.status_code, resp.text)
                raise RuntimeError(f"Database error updating subscription: {resp.text}")
            items = resp.json()
            return items[0] if isinstance(items, list) and items else None

    def list_user_subscriptions(self) -> List[Dict[str, Any]]:
        """List all subscriptions ordered by created_at desc."""
        if not self.is_live:
            return sorted(
                list(self._mock_subscriptions.values()),
                key=lambda x: x.get("created_at", ""),
                reverse=True,
            )

        url = f"{self.supabase_url}/rest/v1/user_subscriptions?select=*&order=created_at.desc"
        with httpx.Client(timeout=self.timeout) as client:
            resp = client.get(url, headers=self._headers())
            if resp.status_code >= 400:
                raise RuntimeError(f"Failed to query subscriptions: {resp.text}")
            return resp.json()

    def delete_user_subscription(self, user_id: str) -> bool:
        """Delete subscription record."""
        if not self.is_live:
            self._mock_subscriptions.pop(user_id, None)
            return True

        url = f"{self.supabase_url}/rest/v1/user_subscriptions?user_id=eq.{user_id}"
        with httpx.Client(timeout=self.timeout) as client:
            resp = client.delete(url, headers=self._headers())
            return resp.status_code < 400

    # =========================================================================
    # 4. User Draft Sheets (/rest/v1/user_draft_sheets)
    # =========================================================================

    def get_user_draft_sheets(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all synchronized draft sheets for a user."""
        if not self.is_live:
            prefix = f"{user_id}:"
            sheets = [v for k, v in self._mock_draft_sheets.items() if k.startswith(prefix)]
            return sorted(sheets, key=lambda x: x.get("updated_at", ""), reverse=True)

        url = (
            f"{self.supabase_url}/rest/v1/user_draft_sheets"
            f"?user_id=eq.{quote(user_id, safe='')}&select=*&order=updated_at.desc"
        )
        with httpx.Client(timeout=self.timeout) as client:
            resp = client.get(url, headers=self._headers())
            if resp.status_code >= 400:
                logger.error("get_user_draft_sheets failed: %s %s", resp.status_code, resp.text)
                return []
            return resp.json()

    def upsert_user_draft_sheets_batch(
        self,
        user_id: str,
        sheets: List[Dict[str, Any]],
    ) -> List[Dict[str, Any]]:
        """Batch-upsert draft sheets in a single round-trip using (user_id, sheet_id) conflict target."""
        if not sheets:
            return []

        now_str = datetime.now(timezone.utc).isoformat()
        records = [
            {
                "user_id": user_id,
                "sheet_id": str(item["sheet_id"]),
                "sheet_name": str(item["sheet_name"]),
                "rows_json": item.get("rows_json") or [],
                "updated_at": now_str,
            }
            for item in sheets
        ]

        if not self.is_live:
            saved: List[Dict[str, Any]] = []
            for rec in records:
                key = f"{user_id}:{rec['sheet_id']}"
                existing = self._mock_draft_sheets.get(key)
                rec["id"] = existing["id"] if existing and "id" in existing else str(uuid.uuid4())
                self._mock_draft_sheets[key] = rec
                saved.append(rec)
            return saved

        url = f"{self.supabase_url}/rest/v1/user_draft_sheets?on_conflict=user_id,sheet_id"
        with httpx.Client(timeout=self.timeout) as client:
            resp = client.post(
                url,
                json=records,
                headers=self._headers(prefer="resolution=merge-duplicates,return=representation"),
            )
            if resp.status_code >= 400:
                logger.error("upsert_user_draft_sheets_batch failed: %s %s", resp.status_code, resp.text)
                raise RuntimeError(f"Database error saving draft sheets: {resp.text}")
            items = resp.json()
            return items if isinstance(items, list) else [items]

    def upsert_user_draft_sheet(
        self,
        user_id: str,
        sheet_id: str,
        sheet_name: str,
        rows_json: List[Any],
    ) -> Dict[str, Any]:
        """Upsert a single draft sheet."""
        results = self.upsert_user_draft_sheets_batch(
            user_id=user_id,
            sheets=[{"sheet_id": sheet_id, "sheet_name": sheet_name, "rows_json": rows_json}],
        )
        return results[0]

    def prune_user_draft_sheets(self, user_id: str, keep_sheet_ids: List[str]) -> bool:
        """Delete user draft sheets whose sheet_id is not in keep_sheet_ids."""
        keep_set = {str(sid) for sid in keep_sheet_ids if str(sid)}
        if not keep_set:
            return self.delete_user_draft_sheets(user_id)

        if not self.is_live:
            prefix = f"{user_id}:"
            to_del = [
                k for k, v in self._mock_draft_sheets.items()
                if k.startswith(prefix) and str(v.get("sheet_id")) not in keep_set
            ]
            for k in to_del:
                self._mock_draft_sheets.pop(k, None)
            return True

        encoded_ids = ",".join(f'"{sid.replace(chr(34), "")}"' for sid in sorted(keep_set))
        url = (
            f"{self.supabase_url}/rest/v1/user_draft_sheets"
            f"?user_id=eq.{quote(user_id, safe='')}&sheet_id=not.in.({encoded_ids})"
        )
        with httpx.Client(timeout=self.timeout) as client:
            resp = client.delete(url, headers=self._headers())
            return resp.status_code < 400

    def delete_user_draft_sheets(self, user_id: str) -> bool:
        """Delete all draft sheets for a user."""
        if not self.is_live:
            keys = [k for k in self._mock_draft_sheets if k.startswith(f"{user_id}:")]
            for k in keys:
                self._mock_draft_sheets.pop(k, None)
            return True

        url = f"{self.supabase_url}/rest/v1/user_draft_sheets?user_id=eq.{quote(user_id, safe='')}"
        with httpx.Client(timeout=self.timeout) as client:
            resp = client.delete(url, headers=self._headers())
            return resp.status_code < 400

    # =========================================================================
    # 5. External Account Deletion Requests (/rest/v1/deletion_requests)
    # =========================================================================

    def create_deletion_request(
        self,
        email: str,
        phone: str = "",
        reason: str = "",
    ) -> Dict[str, Any]:
        """Persist a public web account deletion request."""
        clean_email = email.strip().lower()
        now_str = datetime.now(timezone.utc).isoformat()
        payload = {
            "email": clean_email,
            "phone": (phone or "").strip(),
            "reason": (reason or "").strip(),
            "status": "pending",
        }

        if not self.is_live:
            req_id = str(uuid.uuid4())
            record = {"id": req_id, **payload, "created_at": now_str}
            self._mock_deletion_requests[req_id] = record
            return record

        url = f"{self.supabase_url}/rest/v1/deletion_requests"
        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.post(
                    url,
                    json=payload,
                    headers=self._headers(prefer="return=representation"),
                )
                if resp.status_code < 400:
                    results = resp.json()
                    return results[0] if isinstance(results, list) and results else results
                logger.warning(
                    "deletion_requests insert returned %s (ensure 001_admin_subscriptions.sql is applied): %s",
                    resp.status_code,
                    resp.text,
                )
        except Exception as exc:
            logger.warning("deletion_requests insert failed: %s", exc)
        return {"id": str(uuid.uuid4()), **payload, "created_at": now_str}


# Singleton instance
_supabase_admin_client: Optional[SupabaseAdminClient] = None


def get_supabase_admin() -> SupabaseAdminClient:
    """Get or initialize singleton SupabaseAdminClient."""
    global _supabase_admin_client
    if _supabase_admin_client is None:
        _supabase_admin_client = SupabaseAdminClient()
    return _supabase_admin_client


def reset_supabase_admin_for_tests() -> SupabaseAdminClient:
    """Reset and return a fresh in-memory SupabaseAdminClient (for test isolation)."""
    global _supabase_admin_client
    _supabase_admin_client = SupabaseAdminClient(supabase_url="", service_role_key="")
    return _supabase_admin_client
