"""Admin endpoints for B2B Client Provisioning, Subscription lifecycle, and Device control."""

from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
import logging
from pathlib import Path
import shutil
from typing import Any, Dict, List, Optional

import re
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field, field_validator

_EMAIL_REGEX = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")

try:
    from backend.app.core.auth import AuthenticatedUser, get_admin_user
    from backend.app.core.config import settings
    from backend.app.services.supabase_admin import get_supabase_admin
except (ImportError, ValueError):
    try:
        from app.core.auth import AuthenticatedUser, get_admin_user
        from app.core.config import settings
        from app.services.supabase_admin import get_supabase_admin
    except (ImportError, ValueError):
        from ...core.auth import AuthenticatedUser, get_admin_user
        from ...core.config import settings
        from ...services.supabase_admin import get_supabase_admin

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/admin", tags=["Admin Control"])


# =============================================================================
# Schemas
# =============================================================================

class ProvisionUserIn(BaseModel):
    request_id: Optional[str] = None
    email: str = Field(..., min_length=5, max_length=120)
    password: str = Field(..., min_length=8, max_length=128)
    full_name: str = Field(..., min_length=2, max_length=120)
    business_name: str = Field(..., min_length=2, max_length=150)
    phone: str = Field(..., min_length=8, max_length=25)
    amount_paid_inr: float = Field(default=0.0, ge=0.0)
    payment_notes: Optional[str] = Field(default="", max_length=500)
    subscription_start: Optional[date] = None
    subscription_end: Optional[date] = None

    @field_validator("email")
    @classmethod
    def validate_email_format(cls, v: str) -> str:
        clean = v.strip().lower()
        if not _EMAIL_REGEX.match(clean):
            raise ValueError("Invalid email address format.")
        return clean


class UnblockUserIn(BaseModel):
    amount_paid_inr: Optional[float] = Field(default=None, ge=0.0)
    payment_notes: Optional[str] = Field(default=None, max_length=500)
    subscription_start: Optional[date] = None
    subscription_end: Optional[date] = None


# =============================================================================
# 1. Access Requests Management
# =============================================================================

@router.get("/requests")
async def list_access_requests(
    status_filter: Optional[str] = Query(None, alias="status"),
    admin: AuthenticatedUser = Depends(get_admin_user),
) -> List[Dict[str, Any]]:
    """List client onboarding requests (pending, approved, rejected)."""
    admin_client = get_supabase_admin()
    return admin_client.list_access_requests(status_filter=status_filter)


@router.post("/requests/{request_id}/reject")
async def reject_access_request(
    request_id: str,
    admin: AuthenticatedUser = Depends(get_admin_user),
) -> Dict[str, Any]:
    """Reject an onboarding request."""
    admin_client = get_supabase_admin()
    updated = admin_client.update_access_request_status(request_id, "rejected")
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Access request '{request_id}' not found.",
        )
    return {"ok": True, "request": updated}


# =============================================================================
# 2. User Provisioning & Lifecycle
# =============================================================================

@router.post("/users/provision", status_code=status.HTTP_201_CREATED)
async def provision_user(
    payload: ProvisionUserIn,
    admin: AuthenticatedUser = Depends(get_admin_user),
) -> Dict[str, Any]:
    """Provision a new Supabase Auth user & active B2B subscription record."""
    admin_client = get_supabase_admin()

    # 1. Calculate default dates if not provided
    today = date.today()
    start_date = payload.subscription_start or today
    end_date = payload.subscription_end or (start_date + timedelta(days=30))

    # 2. Create Auth User
    try:
        user_auth = admin_client.create_user(
            email=payload.email,
            password=payload.password,
            full_name=payload.full_name,
            metadata={
                "business_name": payload.business_name,
                "phone": payload.phone,
                "provisioned_by": admin.email or admin.user_id,
            },
        )
    except Exception as e:
        logger.error("Failed to provision auth user %s: %s", payload.email, e)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create user in authentication provider: {e}",
        )

    user_id = str(user_auth.get("id"))

    # 3. Create Subscription Record
    sub_data = {
        "user_id": user_id,
        "email": payload.email.lower(),
        "full_name": payload.full_name,
        "business_name": payload.business_name,
        "phone": payload.phone,
        "amount_paid_inr": payload.amount_paid_inr,
        "payment_notes": payload.payment_notes or "",
        "subscription_start": str(start_date),
        "subscription_end": str(end_date),
        "status": "active",
        "active_session_id": None,
        "active_device_label": None,
    }

    try:
        saved_sub = admin_client.upsert_user_subscription(sub_data)
    except Exception as e:
        logger.error("Failed to save subscription for %s: %s", user_id, e)
        # Attempt cleanup of created auth user
        try:
            admin_client.delete_user(user_id)
        except Exception:
            pass
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database error provisioning subscription: {e}",
        )

    # 4. If request_id provided, mark request as approved
    if payload.request_id:
        try:
            admin_client.update_access_request_status(payload.request_id, "approved")
        except Exception:
            logger.warning("Could not update request_id=%s status", payload.request_id)

    logger.info("Admin %s provisioned user %s (%s)", admin.email, user_id, payload.email)

    return {
        "ok": True,
        "user_id": user_id,
        "email": payload.email.lower(),
        "temporary_password": payload.password,
        "subscription": saved_sub,
    }


@router.get("/users")
async def list_subscribers(
    admin: AuthenticatedUser = Depends(get_admin_user),
) -> List[Dict[str, Any]]:
    """List all registered subscribers with subscription status and active device."""
    admin_client = get_supabase_admin()
    return admin_client.list_user_subscriptions()


@router.post("/users/{user_id}/cancel")
async def cancel_subscription(
    user_id: str,
    admin: AuthenticatedUser = Depends(get_admin_user),
) -> Dict[str, Any]:
    """Cancel subscription (blocks scanning, preserves read-only access to existing data)."""
    admin_client = get_supabase_admin()
    sub = admin_client.get_user_subscription(user_id)
    if not sub:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User subscription '{user_id}' not found.",
        )

    updated = admin_client.update_user_subscription(user_id, {"status": "cancelled"})
    logger.info("Admin %s cancelled subscription for user %s", admin.email, user_id)
    return {"ok": True, "subscription": updated}


@router.post("/users/{user_id}/unblock")
async def unblock_subscription(
    user_id: str,
    payload: UnblockUserIn,
    admin: AuthenticatedUser = Depends(get_admin_user),
) -> Dict[str, Any]:
    """Unblock or renew an account and update dates/payment."""
    admin_client = get_supabase_admin()
    sub = admin_client.get_user_subscription(user_id)
    if not sub:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User subscription '{user_id}' not found.",
        )

    updates: Dict[str, Any] = {"status": "active"}
    if payload.amount_paid_inr is not None:
        updates["amount_paid_inr"] = payload.amount_paid_inr
    if payload.payment_notes is not None:
        updates["payment_notes"] = payload.payment_notes
    if payload.subscription_start:
        updates["subscription_start"] = str(payload.subscription_start)
    if payload.subscription_end:
        updates["subscription_end"] = str(payload.subscription_end)
    elif payload.subscription_start:
        updates["subscription_end"] = str(payload.subscription_start + timedelta(days=30))

    updated = admin_client.update_user_subscription(user_id, updates)
    logger.info("Admin %s unblocked subscription for user %s", admin.email, user_id)
    return {"ok": True, "subscription": updated}


@router.post("/users/{user_id}/reset-device")
async def reset_device_session(
    user_id: str,
    admin: AuthenticatedUser = Depends(get_admin_user),
) -> Dict[str, Any]:
    """Clear active single-device lock if client lost or replaced their phone."""
    admin_client = get_supabase_admin()
    sub = admin_client.get_user_subscription(user_id)
    if not sub:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User subscription '{user_id}' not found.",
        )

    updated = admin_client.update_user_subscription(
        user_id,
        {"active_session_id": None, "active_device_label": None},
    )
    logger.info("Admin %s reset active device session for user %s", admin.email, user_id)
    return {"ok": True, "message": "Device session reset. User can now log in on a new device.", "subscription": updated}


@router.delete("/users/{user_id}")
async def delete_user_and_data(
    user_id: str,
    admin: AuthenticatedUser = Depends(get_admin_user),
) -> Dict[str, Any]:
    """Permanently delete user from Supabase Auth + wipe uploaded files on disk."""
    admin_client = get_supabase_admin()

    # 1. Wipe uploaded photos on disk
    user_dir = settings.DOCUMENT_ROOT / "uploads" / user_id
    if user_dir.exists():
        try:
            shutil.rmtree(user_dir)
            logger.info("Purged upload directory for deleted user %s", user_id)
        except Exception:
            logger.exception("Failed to purge upload dir for %s", user_id)

    # 2. Delete from Supabase Auth (cascades database)
    try:
        admin_client.delete_user(user_id)
    except Exception as e:
        logger.error("Failed to delete user %s: %s", user_id, e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete user: {e}",
        )

    logger.info("Admin %s permanently deleted user %s", admin.email, user_id)
    return {"ok": True, "message": f"User '{user_id}' and all associated records permanently deleted."}
