"""Supabase JWT verification and fail-closed FastAPI auth dependencies."""

from __future__ import annotations

import base64
from dataclasses import dataclass
import hashlib
import hmac
import json
import logging
import threading
import time
from typing import Any, Dict, Optional

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec, rsa
from cryptography.hazmat.primitives.asymmetric.utils import encode_dss_signature
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import httpx

try:
    from backend.app.core.config import settings
except (ImportError, ValueError):
    try:
        from app.core.config import settings
    except (ImportError, ValueError):
        from .config import settings

logger = logging.getLogger(__name__)

_bearer_scheme = HTTPBearer(auto_error=False)
_ALLOWED_ALGORITHMS = {"HS256", "ES256", "RS256"}
_CLOCK_SKEW_SECONDS = 60
_JWKS_CACHE_TTL_SECONDS = 3600

_jwks_lock = threading.Lock()
_jwks_cache: Dict[str, Any] = {"url": "", "expires_at": 0.0, "keys": []}


@dataclass(frozen=True)
class AuthenticatedUser:
    """Verified user identity extracted from a Supabase JWT."""

    user_id: str
    email: Optional[str]
    role: str
    claims: Dict[str, Any]


def _b64url_decode(segment: str) -> bytes:
    """Decode base64url segment with strict padding restoration."""
    padded = segment + "=" * (-len(segment) % 4)
    return base64.urlsafe_b64decode(padded.encode("ascii"))


def _b64url_uint(segment: str) -> int:
    """Decode unsigned big-endian integer from JWK base64url coordinate/modulus."""
    return int.from_bytes(_b64url_decode(segment), "big")


def _fetch_jwks(supabase_url: str, *, force_refresh: bool = False) -> list[dict[str, Any]]:
    """Fetch and cache Supabase public JWKS keys."""
    jwks_url = f"{supabase_url.rstrip('/')}/auth/v1/.well-known/jwks.json"
    now = time.time()

    with _jwks_lock:
        if (
            not force_refresh
            and _jwks_cache["url"] == jwks_url
            and now < _jwks_cache["expires_at"]
            and _jwks_cache["keys"]
        ):
            return list(_jwks_cache["keys"])

    with httpx.Client(timeout=5.0) as client:
        resp = client.get(jwks_url)
        resp.raise_for_status()
        payload = resp.json()

    keys = payload.get("keys")
    if not isinstance(keys, list):
        raise ValueError("Invalid JWKS payload from auth provider")

    with _jwks_lock:
        _jwks_cache["url"] = jwks_url
        _jwks_cache["expires_at"] = time.time() + _JWKS_CACHE_TTL_SECONDS
        _jwks_cache["keys"] = keys

    return keys


def _verify_hs256(signing_input: bytes, signature: bytes, secret: str) -> bool:
    expected = hmac.new(secret.encode("utf-8"), signing_input, hashlib.sha256).digest()
    return hmac.compare_digest(expected, signature)


def _verify_asymmetric(
    signing_input: bytes,
    signature: bytes,
    alg: str,
    jwk: Dict[str, Any],
) -> bool:
    kty = jwk.get("kty")
    try:
        if alg == "RS256" and kty == "RSA":
            pub = rsa.RSAPublicNumbers(
                _b64url_uint(jwk["e"]),
                _b64url_uint(jwk["n"]),
            ).public_key()
            from cryptography.hazmat.primitives.asymmetric import padding

            pub.verify(signature, signing_input, padding.PKCS1v15(), hashes.SHA256())
            return True

        if alg == "ES256" and kty == "EC":
            if len(signature) != 64:
                return False
            pub = ec.EllipticCurvePublicNumbers(
                _b64url_uint(jwk["x"]),
                _b64url_uint(jwk["y"]),
                ec.SECP256R1(),
            ).public_key()
            r = int.from_bytes(signature[:32], "big")
            s = int.from_bytes(signature[32:], "big")
            pub.verify(encode_dss_signature(r, s), signing_input, ec.ECDSA(hashes.SHA256()))
            return True
    except (InvalidSignature, KeyError, ValueError, TypeError):
        return False

    return False


def _match_jwk(keys: list[dict[str, Any]], kid: Optional[str]) -> Optional[Dict[str, Any]]:
    if kid:
        for key in keys:
            if key.get("kid") == kid:
                return key
        return None
    return keys[0] if len(keys) == 1 else None


def verify_supabase_jwt(token: str) -> AuthenticatedUser:
    """Validate JWT structure, cryptographic signature, and standard Supabase claims."""
    parts = token.split(".")
    if len(parts) != 3:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    header_b64, payload_b64, sig_b64 = parts
    try:
        header = json.loads(_b64url_decode(header_b64))
        claims = json.loads(_b64url_decode(payload_b64))
        signature = _b64url_decode(sig_b64)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Malformed authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not isinstance(header, dict) or not isinstance(claims, dict):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    alg = header.get("alg")
    if alg not in _ALLOWED_ALGORITHMS:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Unsupported token signing algorithm.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    signing_input = f"{header_b64}.{payload_b64}".encode("ascii")
    jwt_secret = settings.SUPABASE_JWT_SECRET.strip()
    supabase_url = settings.SUPABASE_URL.strip()

    if not jwt_secret and not supabase_url:
        logger.error("Authentication rejected: neither SUPABASE_JWT_SECRET nor SUPABASE_URL is configured.")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service is not configured.",
        )

    verified = False
    if alg == "HS256":
        if not jwt_secret:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token algorithm is not accepted by server configuration.",
                headers={"WWW-Authenticate": "Bearer"},
            )
        verified = _verify_hs256(signing_input, signature, jwt_secret)
    else:
        if not supabase_url:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="JWKS verification URL is not configured.",
            )
        try:
            keys = _fetch_jwks(supabase_url)
            jwk = _match_jwk(keys, header.get("kid"))
            if jwk is None:
                keys = _fetch_jwks(supabase_url, force_refresh=True)
                jwk = _match_jwk(keys, header.get("kid"))
        except Exception:
            logger.exception("Failed to fetch Supabase JWKS for token verification.")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Authentication provider is temporarily unavailable.",
            )
        if jwk is not None:
            verified = _verify_asymmetric(signing_input, signature, alg, jwk)

    if not verified:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    now = time.time()
    exp = claims.get("exp")
    if not isinstance(exp, (int, float)) or exp < (now - _CLOCK_SKEW_SECONDS):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token has expired.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    nbf = claims.get("nbf")
    if isinstance(nbf, (int, float)) and nbf > (now + _CLOCK_SKEW_SECONDS):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token is not yet valid.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    sub = claims.get("sub")
    if not isinstance(sub, str) or not sub.strip():
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing subject identity.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    aud = claims.get("aud")
    if aud is not None:
        aud_list = aud if isinstance(aud, list) else [aud]
        if "authenticated" not in aud_list:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token audience.",
                headers={"WWW-Authenticate": "Bearer"},
            )

    iss = claims.get("iss")
    if supabase_url and isinstance(iss, str):
        expected_iss = f"{supabase_url.rstrip('/')}/auth/v1"
        if iss.rstrip("/") != expected_iss:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token issuer.",
                headers={"WWW-Authenticate": "Bearer"},
            )

    return AuthenticatedUser(
        user_id=sub.strip(),
        email=claims.get("email") if isinstance(claims.get("email"), str) else None,
        role=str(claims.get("role") or "authenticated"),
        claims=claims,
    )


def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme),
) -> AuthenticatedUser:
    """FastAPI dependency enforcing verified Supabase Bearer authentication (fail-closed)."""
    if not settings.AUTH_REQUIRED:
        return AuthenticatedUser(
            user_id="dev-local-user",
            email=None,
            role="authenticated",
            claims={"auth_bypassed": True},
        )

    if credentials is None or credentials.scheme.lower() != "bearer" or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication credentials required.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return verify_supabase_jwt(credentials.credentials)


def get_admin_user(
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> AuthenticatedUser:
    """FastAPI dependency enforcing that current user is an authorized administrator."""
    if not settings.AUTH_REQUIRED:
        return current_user

    admin_emails = settings.get_admin_emails()
    user_email = (current_user.email or "").strip().lower()

    if not user_email or user_email not in admin_emails:
        logger.warning(
            "Access to admin endpoint rejected for user_id=%s, email=%s",
            current_user.user_id,
            user_email or "<none>",
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Administrative privileges required.",
        )
    return current_user


def clear_jwks_cache() -> None:
    """Clear in-memory JWKS cache (for tests)."""
    with _jwks_lock:
        _jwks_cache["url"] = ""
        _jwks_cache["expires_at"] = 0.0
        _jwks_cache["keys"] = []
