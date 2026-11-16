"""Subscription and Single-Device Session Guard dependencies for FastAPI routes."""

from __future__ import annotations

from datetime import date, datetime, timedelta
import logging
from typing import Optional

from fastapi import Depends, Header, HTTPException, status

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
        from .auth import AuthenticatedUser, get_current_user
        from .config import settings
        from ..services.supabase_admin import get_supabase_admin

logger = logging.getLogger(__name__)


def verify_active_session(
    user: AuthenticatedUser,
    x_device_session_id: Optional[str] = None,
) -> None:
    """Ensure caller's device session ID matches the user's registered active session.
    
    If active_session_id is set in user_subscriptions and does not match
    x_device_session_id, rejects with 409 Conflict.
    """
    if not settings.AUTH_REQUIRED:
        return

    admin_client = get_supabase_admin()
    sub = admin_client.get_user_subscription(user.user_id)
    if not sub:
        return

    active_session = sub.get("active_session_id")
    if active_session:
        clean_provided = (x_device_session_id or "").strip().lower()
        clean_expected = str(active_session).strip().lower()
        if clean_provided != clean_expected:
            active_device = sub.get("active_device_label") or "another device"
            logger.warning(
                "Device session conflict for user=%s. Registered=%s (%s), Provided=%s",
                user.user_id,
                clean_expected,
                active_device,
                clean_provided or "<none>",
            )
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"This account is currently active on {active_device}. Only one device may be active at a time.",
            )


def require_active_subscription(
    current_user: AuthenticatedUser = Depends(get_current_user),
    x_device_session_id: Optional[str] = Header(None, alias="X-Device-Session-Id"),
) -> AuthenticatedUser:
    """Enforce active subscription + valid single-device session.
    
    Applied ONLY to scan/extraction endpoints (POST /ocr, POST /extract-text).
    Allows existing files and draft sheets to remain accessible in view-only mode on expiry.
    """
    if not settings.AUTH_REQUIRED:
        return current_user

    # 1. Enforce single-device session lock
    verify_active_session(current_user, x_device_session_id)

    # 2. Check subscription status & validity dates
    admin_client = get_supabase_admin()
    sub = admin_client.get_user_subscription(current_user.user_id)

    # In production/live auth with a configured Supabase backend, a subscription record must exist and be active
    if not sub:
        if admin_client.is_live:
            logger.warning("No subscription record found for user_id=%s", current_user.user_id)
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Subscription expired or blocked. Scanning is disabled; existing data remains viewable.",
            )
        # In non-production mock fallback without live Supabase, default to active for tests/dev
        sub = admin_client.upsert_user_subscription({
            "user_id": current_user.user_id,
            "email": current_user.email or f"{current_user.user_id}@billbooks.app",
            "status": "active",
            "subscription_start": str(date.today()),
            "subscription_end": str(date.today() + timedelta(days=30)),
        })

    sub_status = (sub.get("status") or "").strip().lower()
    if sub_status != "active":
        logger.info(
            "User %s attempted scan with inactive status '%s'",
            current_user.user_id,
            sub_status,
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Subscription expired or blocked. Scanning is disabled; existing data remains viewable.",
        )

    # Date range validation
    today = date.today()
    start_raw = sub.get("subscription_start")
    end_raw = sub.get("subscription_end")

    try:
        start_date = (
            date.fromisoformat(str(start_raw)[:10]) if start_raw else today
        )
        end_date = (
            date.fromisoformat(str(end_raw)[:10]) if end_raw else today
        )
    except (ValueError, TypeError):
        start_date = today
        end_date = today

    if not (start_date <= today <= end_date):
        logger.info(
            "User %s subscription out of date bounds (%s to %s, today=%s)",
            current_user.user_id,
            start_date,
            end_date,
            today,
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Subscription expired or blocked. Scanning is disabled; existing data remains viewable.",
        )

    return current_user
