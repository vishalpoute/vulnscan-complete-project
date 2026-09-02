from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import auth as firebase_auth

from core.database import MongoDB
from core.security import decode_firebase_token, security, verify_firebase_token
from models.user import (
    ALLOWED_SCAN_TYPES,
    SCAN_LIMITS,
    DeleteAccountRequest,
    SubscriptionInfo,
    SubscriptionTier,
    UpdateUserProfileRequest,
    UserProfile,
)


router = APIRouter(tags=["users"])


def _normalize_tier(value: str | None) -> SubscriptionTier:
    try:
        return SubscriptionTier(value or SubscriptionTier.FREE.value)
    except ValueError:
        return SubscriptionTier.FREE


def _subscription_from_user(user: dict | None) -> SubscriptionInfo:
    tier = _normalize_tier((user or {}).get("subscription_tier") or (user or {}).get("tier"))
    scans_used = int((user or {}).get("scans_used", 0))
    return SubscriptionInfo(
        tier=tier,
        scans_used=scans_used,
        scans_limit=int((user or {}).get("scans_limit", SCAN_LIMITS[tier])),
        allowed_scan_types=(user or {}).get("allowed_scan_types", ALLOWED_SCAN_TYPES[tier]),
        expires_at=(user or {}).get("subscription_expires_at")
        or (datetime.utcnow() + timedelta(days=365) if tier == SubscriptionTier.FREE else None),
    )


async def _upsert_user_from_token(decoded_token: dict) -> dict:
    """Ensure a MongoDB user record exists for the authenticated Firebase user."""
    uid = decoded_token["uid"]
    email = decoded_token.get("email")
    display_name = decoded_token.get("name")
    now = datetime.utcnow()

    db = MongoDB.get_db()
    users_collection = db["users"]
    existing = await users_collection.find_one({"uid": uid})

    if existing is None:
        user_doc = {
            "uid": uid,
            "email": email,
            "display_name": display_name,
            "subscription_tier": SubscriptionTier.FREE.value,
            "scans_used": 0,
            "scans_limit": SCAN_LIMITS[SubscriptionTier.FREE],
            "allowed_scan_types": ALLOWED_SCAN_TYPES[SubscriptionTier.FREE],
            "created_at": now,
            "updated_at": now,
        }
        await users_collection.insert_one(user_doc)
        return user_doc

    update_fields = {"updated_at": now}
    if email and existing.get("email") != email:
        update_fields["email"] = email
    if display_name and existing.get("display_name") != display_name:
        update_fields["display_name"] = display_name

    if update_fields:
        await users_collection.update_one({"uid": uid}, {"$set": update_fields})
        existing.update(update_fields)

    return existing


@router.get("/user/subscription", response_model=SubscriptionInfo, include_in_schema=False)
@router.get("/users/subscription", response_model=SubscriptionInfo)
async def get_subscription(credentials=Depends(security)):
    """Get user's current subscription information."""
    uid = await verify_firebase_token(credentials)

    db = MongoDB.get_db()
    user = await db["users"].find_one({"uid": uid})
    return _subscription_from_user(user)


@router.get("/users/profile", response_model=UserProfile)
async def get_profile(credentials=Depends(security)):
    """Get the authenticated user's profile."""
    decoded = await decode_firebase_token(credentials)
    user = await _upsert_user_from_token(decoded)
    return UserProfile(
        uid=user["uid"],
        email=user.get("email"),
        display_name=user.get("display_name"),
        created_at=user.get("created_at", datetime.utcnow()),
        updated_at=user.get("updated_at"),
        subscription=_subscription_from_user(user),
    )


@router.put("/users/profile", response_model=UserProfile)
async def update_profile(
    request: UpdateUserProfileRequest,
    credentials=Depends(security),
):
    """Update editable profile fields for the authenticated user."""
    uid = await verify_firebase_token(credentials)
    now = datetime.utcnow()

    db = MongoDB.get_db()
    update_fields = {"updated_at": now}
    if request.display_name is not None:
        update_fields["display_name"] = request.display_name.strip() or None

    await db["users"].update_one({"uid": uid}, {"$set": update_fields}, upsert=True)
    user = await db["users"].find_one({"uid": uid})

    return UserProfile(
        uid=uid,
        email=user.get("email") if user else None,
        display_name=(user or {}).get("display_name"),
        created_at=(user or {}).get("created_at", now),
        updated_at=now,
        subscription=_subscription_from_user(user),
    )


@router.delete("/user/account", include_in_schema=False)
@router.delete("/users/account")
async def delete_account(
    request: DeleteAccountRequest,
    credentials=Depends(security),
):
    """Delete user account and all associated MongoDB data."""
    uid = await verify_firebase_token(credentials)
    if not request.confirm:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Must confirm account deletion",
        )

    db = MongoDB.get_db()
    user_result = await db["users"].delete_one({"uid": uid})
    scans_result = await db["scans"].delete_many({"uid": uid})

    firebase_deleted = False
    try:
        firebase_auth.delete_user(uid)
        firebase_deleted = True
    except Exception as exc:
        print(f"⚠ Firebase user deletion skipped/failed for {uid}: {exc}")

    return {
        "message": "Account deletion processed",
        "user_deleted": user_result.deleted_count > 0,
        "scans_deleted": scans_result.deleted_count,
        "firebase_deleted": firebase_deleted,
    }
