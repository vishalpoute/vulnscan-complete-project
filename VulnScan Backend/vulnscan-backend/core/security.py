"""Firebase authentication and admin authorization helpers."""

from pathlib import Path
from typing import Any

import firebase_admin
from fastapi import HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth
from firebase_admin import credentials as firebase_credentials

from .config import settings


security = HTTPBearer(auto_error=True)


def _build_firebase_certificate():
    """Build a Firebase certificate from a JSON file or inline env fields."""
    if settings.FIREBASE_CREDENTIALS_PATH:
        credentials_path = Path(settings.FIREBASE_CREDENTIALS_PATH)
        if credentials_path.exists():
            return firebase_credentials.Certificate(str(credentials_path))
        print(f"[WARN] Firebase credentials file not found: {credentials_path}")

    if settings.has_inline_firebase_credentials:
        return firebase_credentials.Certificate(
            {
                "type": "service_account",
                "project_id": settings.FIREBASE_PROJECT_ID,
                "private_key": settings.FIREBASE_PRIVATE_KEY.replace("\\n", "\n"),
                "client_email": settings.FIREBASE_CLIENT_EMAIL,
                "token_uri": "https://oauth2.googleapis.com/token",
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
                "client_x509_cert_url": (
                    "https://www.googleapis.com/robot/v1/metadata/x509/"
                    f"{settings.FIREBASE_CLIENT_EMAIL}"
                ),
            }
        )

    return None


def initialize_firebase_admin() -> bool:
    """Initialize Firebase Admin SDK once.

    Returns False instead of raising when credentials are absent so local docs,
    health checks, and database-only endpoints can still start during setup.
    """
    if firebase_admin._apps:
        return True

    certificate = _build_firebase_certificate()
    if certificate is None:
        print("[WARN] Firebase credentials are not configured; auth endpoints are disabled.")
        return False

    try:
        options: dict[str, Any] = {}
        if settings.FIREBASE_DATABASE_URL:
            options["databaseURL"] = settings.FIREBASE_DATABASE_URL
        firebase_admin.initialize_app(certificate, options=options or None)
        print("[OK] Firebase Admin SDK initialized successfully")
        return True
    except Exception as exc:
        print(f"[WARN] Firebase initialization failed: {exc}")
        return False


def _require_firebase_admin() -> None:
    """Raise an HTTP 503 if Firebase Admin SDK is unavailable."""
    if not initialize_firebase_admin():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Firebase is not configured. Set FIREBASE_CREDENTIALS_PATH or inline service-account variables.",
        )


async def decode_firebase_token(credentials: HTTPAuthorizationCredentials) -> dict[str, Any]:
    """Verify and decode a Firebase ID token from an Authorization header."""
    _require_firebase_admin()
    try:
        return auth.verify_id_token(credentials.credentials)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {exc}",
        ) from exc


async def verify_firebase_token(credentials: HTTPAuthorizationCredentials) -> str:
    """Return the authenticated Firebase uid, or raise HTTP 401."""
    decoded_token = await decode_firebase_token(credentials)
    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token: missing uid",
        )
    return uid


async def verify_admin_token(credentials: HTTPAuthorizationCredentials) -> str:
    """Return uid when the token belongs to an admin user."""
    decoded_token = await decode_firebase_token(credentials)
    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token: missing uid",
        )

    token_email = (decoded_token.get("email") or "").lower()
    configured_admin_email = (settings.ADMIN_EMAIL or "").lower()
    is_admin = bool(decoded_token.get("isAdmin")) or (
        configured_admin_email and token_email == configured_admin_email
    )

    if not is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )

    return uid
