"""Authentication endpoints documented for the VulnScan API."""

from datetime import datetime
from typing import Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import auth as firebase_auth
from pydantic import BaseModel, EmailStr, Field

from core.config import settings
from core.database import MongoDB
from core.firestore import FirestoreDB
from core.security import decode_firebase_token, initialize_firebase_admin, security
from models.user import ALLOWED_SCAN_TYPES, SCAN_LIMITS, SubscriptionTier


router = APIRouter(prefix="/auth", tags=["auth"])


class TokenVerifyRequest(BaseModel):
    token: str


class TokenVerifyResponse(BaseModel):
    uid: str
    email: Optional[EmailStr] = None
    email_verified: bool = False


class AuthEmailPasswordRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6)
    display_name: Optional[str] = Field(default=None, max_length=120)


class AuthResponse(BaseModel):
    uid: str
    email: EmailStr
    id_token: str
    refresh_token: str
    expires_in: int


class MessageResponse(BaseModel):
    message: str


def _identity_toolkit_url(action: str) -> str:
    if not settings.FIREBASE_WEB_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIREBASE_WEB_API_KEY is required for email/password auth endpoints.",
        )
    return f"https://identitytoolkit.googleapis.com/v1/accounts:{action}?key={settings.FIREBASE_WEB_API_KEY}"


async def _sync_user_record(uid: str, email: str | None, display_name: str | None = None) -> None:
    """Create/update user data in MongoDB and Firestore when available."""
    now = datetime.utcnow()

    try:
        db = MongoDB.get_db()
        await db["users"].update_one(
            {"uid": uid},
            {
                "$set": {
                    "email": email,
                    "display_name": display_name,
                    "updated_at": now,
                },
                "$setOnInsert": {
                    "uid": uid,
                    "subscription_tier": SubscriptionTier.FREE.value,
                    "scans_used": 0,
                    "scans_limit": SCAN_LIMITS[SubscriptionTier.FREE],
                    "allowed_scan_types": ALLOWED_SCAN_TYPES[SubscriptionTier.FREE],
                    "created_at": now,
                },
            },
            upsert=True,
        )
    except HTTPException as exc:
        print(f"⚠ MongoDB user sync skipped for {uid}: {exc.detail}")
    except Exception as exc:
        print(f"⚠ Failed to sync MongoDB user {uid}: {exc}")

    if email:
        await FirestoreDB.create_user_document(uid, email, display_name)


async def _call_firebase_auth(action: str, payload: dict) -> dict:
    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.post(_identity_toolkit_url(action), json=payload)

    data = response.json()
    if response.status_code >= 400:
        firebase_message = data.get("error", {}).get("message", "Firebase authentication failed")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=firebase_message.replace("_", " ").title(),
        )
    return data


@router.post("/verify", response_model=TokenVerifyResponse)
async def verify_token(request: TokenVerifyRequest):
    """Verify a Firebase ID token supplied in the request body."""
    if not initialize_firebase_admin():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Firebase Admin SDK is not configured.",
        )

    try:
        decoded = firebase_auth.verify_id_token(request.token)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {exc}",
        ) from exc

    uid = decoded.get("uid")
    if not uid:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token: missing uid")

    await _sync_user_record(uid, decoded.get("email"), decoded.get("name"))
    return TokenVerifyResponse(
        uid=uid,
        email=decoded.get("email"),
        email_verified=bool(decoded.get("email_verified", False)),
    )


@router.post("/register", response_model=AuthResponse)
async def register(request: AuthEmailPasswordRequest):
    """Register a Firebase email/password user through the documented backend API."""
    data = await _call_firebase_auth(
        "signUp",
        {
            "email": str(request.email),
            "password": request.password,
            "returnSecureToken": True,
        },
    )

    uid = data["localId"]
    if request.display_name and initialize_firebase_admin():
        firebase_auth.update_user(uid, display_name=request.display_name)

    await _sync_user_record(uid, str(request.email), request.display_name)
    return AuthResponse(
        uid=uid,
        email=request.email,
        id_token=data["idToken"],
        refresh_token=data["refreshToken"],
        expires_in=int(data.get("expiresIn", 3600)),
    )


@router.post("/login", response_model=AuthResponse)
async def login(request: AuthEmailPasswordRequest):
    """Login a Firebase email/password user through the documented backend API."""
    data = await _call_firebase_auth(
        "signInWithPassword",
        {
            "email": str(request.email),
            "password": request.password,
            "returnSecureToken": True,
        },
    )

    await _sync_user_record(data["localId"], data.get("email"), request.display_name)
    return AuthResponse(
        uid=data["localId"],
        email=data["email"],
        id_token=data["idToken"],
        refresh_token=data["refreshToken"],
        expires_in=int(data.get("expiresIn", 3600)),
    )


@router.post("/logout", response_model=MessageResponse)
async def logout():
    """Logout endpoint for API compatibility; clients should discard tokens locally."""
    return MessageResponse(message="Logged out successfully. Remove the client token locally.")


@router.get("/me", response_model=TokenVerifyResponse)
async def get_current_user(credentials=Depends(security)):
    """Return the current authenticated Firebase user."""
    decoded = await decode_firebase_token(credentials)
    uid = decoded.get("uid")
    if not uid:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token: missing uid")

    await _sync_user_record(uid, decoded.get("email"), decoded.get("name"))
    return TokenVerifyResponse(
        uid=uid,
        email=decoded.get("email"),
        email_verified=bool(decoded.get("email_verified", False)),
    )
