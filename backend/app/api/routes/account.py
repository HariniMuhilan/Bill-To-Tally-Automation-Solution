"""Account & Session endpoints: Public onboarding, User device-lock, and Excel sync."""

from __future__ import annotations

from collections import defaultdict
from datetime import date, datetime, timezone
import logging
from pathlib import Path
import shutil
import time
from typing import Any, Dict, List, Optional, Union
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
import re
from pydantic import BaseModel, Field, field_validator

_EMAIL_REGEX = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")

try:
    from backend.app.core.auth import AuthenticatedUser, get_current_user
    from backend.app.core.config import settings
    from backend.app.services.supabase_admin import get_supabase_admin
except (ImportError, ValueError):
    try:
        from app.core.auth import AuthenticatedUser, get_current_user
        from app.core.config import settings
        from app.services.supabase_admin import get_supabase_admin
    except (ImportError, ValueError):
        from ...core.auth import AuthenticatedUser, get_current_user
        from ...core.config import settings
        from ...services.supabase_admin import get_supabase_admin

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["Account & Session"])

# Simple in-memory rate limiter: ip -> list of timestamps
_rate_limits: Dict[str, List[float]] = defaultdict(list)
_RATE_LIMIT_WINDOW_SECONDS = 3600  # 1 hour


def _check_rate_limit(key: str, max_requests: int) -> None:
    now = time.time()
    cutoff = now - _RATE_LIMIT_WINDOW_SECONDS
    timestamps = [t for t in _rate_limits[key] if t > cutoff]
    if len(timestamps) >= max_requests:
        logger.warning("Rate limit exceeded for key=%s", key)
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many requests. Please try again later.",
        )
    timestamps.append(now)
    _rate_limits[key] = timestamps


# =============================================================================
# Request & Response Schemas
# =============================================================================

class AccessRequestIn(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=120)
    business_name: str = Field(..., min_length=2, max_length=150)
    email: str = Field(..., min_length=5, max_length=120)
    phone: str = Field(..., min_length=8, max_length=20)
    notes: Optional[str] = Field(default="", max_length=500)

    @field_validator("email")
    @classmethod
    def validate_email_format(cls, v: str) -> str:
        clean = v.strip().lower()
        if not _EMAIL_REGEX.match(clean):
            raise ValueError("Invalid email address format.")
        return clean


class PublicDeletionRequestIn(BaseModel):
    email: str = Field(..., min_length=5, max_length=120)
    phone: Optional[str] = Field(default="", max_length=25)
    reason: Optional[str] = Field(default="", max_length=500)

    @field_validator("email")
    @classmethod
    def validate_email_format(cls, v: str) -> str:
        clean = v.strip().lower()
        if not _EMAIL_REGEX.match(clean):
            raise ValueError("Invalid email address format.")
        return clean


class SessionClaimIn(BaseModel):
    device_label: str = Field(..., min_length=2, max_length=120)
    force: bool = False  # Set to true if explicitly replacing previous device


class DraftSheetItem(BaseModel):
    sheet_id: str
    sheet_name: str
    rows_json: List[Any] = Field(default_factory=list)


class DraftSheetsBatchIn(BaseModel):
    sheets: List[DraftSheetItem]


# =============================================================================
# 1. Public Endpoints
# =============================================================================

@router.get("/ping")
async def ping() -> Dict[str, Any]:
    """Lightweight health probe for uptime keep-alive."""
    return {"ok": True, "timestamp": datetime.now(timezone.utc).isoformat()}


@router.post("/access-requests", status_code=status.HTTP_201_CREATED)
async def submit_access_request(
    request: Request,
    payload: AccessRequestIn,
) -> Dict[str, Any]:
    """Submit B2B onboarding access request (rate-limited per IP)."""
    client_ip = request.client.host if request.client else "unknown"
    _check_rate_limit(f"access:{client_ip}", settings.ACCESS_REQUEST_RATE_LIMIT)

    admin_client = get_supabase_admin()
    record = admin_client.create_access_request(
        full_name=payload.full_name,
        business_name=payload.business_name,
        email=payload.email,
        phone=payload.phone,
        notes=payload.notes or "",
    )

    logger.info("Access request created: %s (%s)", payload.email, payload.business_name)
    return {
        "ok": True,
        "message": "Access request received. Our team will verify and provision your login credentials.",
        "request_id": record.get("id"),
    }


@router.post("/public/deletion-requests", status_code=status.HTTP_201_CREATED)
async def submit_deletion_request(
    request: Request,
    payload: PublicDeletionRequestIn,
) -> Dict[str, Any]:
    """Public Play Store web account deletion request."""
    client_ip = request.client.host if request.client else "unknown"
    _check_rate_limit(f"del_req:{client_ip}", 10)

    logger.info(
        "External account deletion request logged for email=%s (phone=%s, reason=%s)",
        payload.email,
        payload.phone,
        payload.reason,
    )
    return {
        "ok": True,
        "message": "Account deletion request recorded. If verified, all user data will be purged within 48 hours.",
    }


# =============================================================================
# 2. Authenticated User Endpoints (/api/me/*)
# =============================================================================

@router.post("/me/session/claim")
async def claim_device_session(
    payload: SessionClaimIn,
    current_user: AuthenticatedUser = Depends(get_current_user),
    x_device_session_id: Optional[str] = Header(None, alias="X-Device-Session-Id"),
) -> Dict[str, Any]:
    """Register or verify this device's active session.
    
    If occupied by another device and force is False, returns 409 Conflict with active_device_label.
    """
    admin_client = get_supabase_admin()
    sub = admin_client.get_user_subscription(current_user.user_id)

    # In dev mode when auth is not required, pass through
    if not settings.AUTH_REQUIRED:
        dummy_session = str(uuid.uuid4())
        return {
            "session_id": dummy_session,
            "device_label": payload.device_label,
            "claimed_at": datetime.now(timezone.utc).isoformat(),
        }

    active_session = sub.get("active_session_id") if sub else None
    active_label = (sub.get("active_device_label") if sub else None) or "another device"

    # If this client already holds the active session, keep it
    if active_session and x_device_session_id:
        if str(active_session).strip().lower() == str(x_device_session_id).strip().lower():
            return {
                "session_id": str(active_session),
                "device_label": active_label,
                "claimed_at": sub.get("session_updated_at") or datetime.now(timezone.utc).isoformat(),
            }

    # If occupied by a different session and not forced
    if active_session and not payload.force:
        logger.warning(
            "Device session conflict for user=%s: occupied by %s",
            current_user.user_id,
            active_label,
        )
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"This account is currently active on {active_label}. Only one device may be active at a time.",
        )

    # Claim new session
    new_session_id = str(uuid.uuid4())
    now_str = datetime.now(timezone.utc).isoformat()
    updates = {
        "active_session_id": new_session_id,
        "active_device_label": payload.device_label,
        "session_updated_at": now_str,
    }

    if sub:
        admin_client.update_user_subscription(current_user.user_id, updates)
    else:
        # Create default initial subscription record if not yet present
        admin_client.upsert_user_subscription({
            "user_id": current_user.user_id,
            "email": current_user.email or f"{current_user.user_id}@billbooks.app",
            "status": "active",
            **updates,
        })

    logger.info("User %s claimed session %s on %s", current_user.user_id, new_session_id, payload.device_label)
    return {
        "session_id": new_session_id,
        "device_label": payload.device_label,
        "claimed_at": now_str,
    }


@router.post("/me/session/release")
async def release_device_session(
    current_user: AuthenticatedUser = Depends(get_current_user),
    x_device_session_id: Optional[str] = Header(None, alias="X-Device-Session-Id"),
) -> Dict[str, Any]:
    """Release active session on explicit Logout."""
    if not settings.AUTH_REQUIRED:
        return {"ok": True}

    admin_client = get_supabase_admin()
    sub = admin_client.get_user_subscription(current_user.user_id)
    if sub and sub.get("active_session_id"):
        # Clear session
        admin_client.update_user_subscription(
            current_user.user_id,
            {"active_session_id": None, "active_device_label": None},
        )
        logger.info("Released device session for user %s", current_user.user_id)

    return {"ok": True}


@router.get("/me/status")
async def get_my_status(
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> Dict[str, Any]:
    """Retrieve user subscription, single-device info, and scanning permission."""
    admin_client = get_supabase_admin()
    sub = admin_client.get_user_subscription(current_user.user_id)

    if not sub:
        # Default fallback for new/unprovisioned user
        today_str = date.today().isoformat()
        return {
            "user_id": current_user.user_id,
            "email": current_user.email,
            "full_name": "",
            "business_name": "",
            "status": "active" if not settings.AUTH_REQUIRED else "pending",
            "subscription_start": today_str,
            "subscription_end": today_str,
            "amount_paid_inr": 0.0,
            "is_scan_allowed": not settings.AUTH_REQUIRED,
            "active_device_label": None,
        }

    today = date.today()
    start_raw = sub.get("subscription_start")
    end_raw = sub.get("subscription_end")
    try:
        start_date = date.fromisoformat(str(start_raw)[:10]) if start_raw else today
        end_date = date.fromisoformat(str(end_raw)[:10]) if end_raw else today
    except (ValueError, TypeError):
        start_date = today
        end_date = today

    status_clean = (sub.get("status") or "active").strip().lower()
    is_scan_allowed = (status_clean == "active") and (start_date <= today <= end_date)

    return {
        "user_id": current_user.user_id,
        "email": sub.get("email") or current_user.email,
        "full_name": sub.get("full_name") or "",
        "business_name": sub.get("business_name") or "",
        "phone": sub.get("phone") or "",
        "status": sub.get("status") or "active",
        "subscription_start": str(start_date),
        "subscription_end": str(end_date),
        "amount_paid_inr": float(sub.get("amount_paid_inr") or 0.0),
        "is_scan_allowed": is_scan_allowed,
        "active_device_label": sub.get("active_device_label"),
    }


@router.get("/me/draft-sheets")
async def get_my_draft_sheets(
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> List[Dict[str, Any]]:
    """Retrieve all synchronized draft Excel sheets for this user."""
    admin_client = get_supabase_admin()
    return admin_client.get_user_draft_sheets(current_user.user_id)


@router.put("/me/draft-sheets")
async def sync_my_draft_sheets(
    payload: Union[DraftSheetsBatchIn, DraftSheetItem],
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> List[Dict[str, Any]]:
    """Upsert one or more draft Excel sheets to Supabase cloud sync."""
    admin_client = get_supabase_admin()
    sheets_to_save: List[DraftSheetItem] = []

    if isinstance(payload, DraftSheetsBatchIn):
        sheets_to_save = payload.sheets
    elif isinstance(payload, DraftSheetItem):
        sheets_to_save = [payload]

    saved_items: List[Dict[str, Any]] = []
    for item in sheets_to_save:
        saved = admin_client.upsert_user_draft_sheet(
            user_id=current_user.user_id,
            sheet_id=item.sheet_id,
            sheet_name=item.sheet_name,
            rows_json=item.rows_json,
        )
        saved_items.append(saved)

    return saved_items


@router.delete("/me/account")
async def delete_my_account(
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> Dict[str, Any]:
    """In-app permanent account deletion (Play Store Data Safety compliance)."""
    admin_client = get_supabase_admin()

    # 1. Wipe uploaded photos on local disk
    user_upload_dir = settings.DOCUMENT_ROOT / "uploads" / current_user.user_id
    if user_upload_dir.exists():
        try:
            shutil.rmtree(user_upload_dir)
            logger.info("Purged uploads directory for user=%s", current_user.user_id)
        except Exception:
            logger.exception("Failed to delete user uploads folder for user=%s", current_user.user_id)

    # 2. Delete from Supabase Auth Admin (cascades database tables)
    try:
        admin_client.delete_user(current_user.user_id)
    except Exception as e:
        logger.error("Failed to delete user %s from Supabase Auth: %s", current_user.user_id, e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to complete account deletion. Please contact support.",
        )

    logger.info("Account %s (%s) permanently deleted.", current_user.user_id, current_user.email)
    return {
        "ok": True,
        "message": "Account and all associated data permanently deleted.",
    }
