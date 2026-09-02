from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, EmailStr, Field


class SubscriptionTier(str, Enum):
    FREE = "free"
    PRO = "pro"
    ENTERPRISE = "enterprise"


SCAN_LIMITS = {
    SubscriptionTier.FREE: 5,
    SubscriptionTier.PRO: 100,
    SubscriptionTier.ENTERPRISE: 1_000_000,
}

ALLOWED_SCAN_TYPES = {
    SubscriptionTier.FREE: ["web", "github_repo"],
    SubscriptionTier.PRO: ["web", "github_repo", "android", "ios"],
    SubscriptionTier.ENTERPRISE: ["web", "github_repo", "android", "ios"],
}


class SubscriptionInfo(BaseModel):
    """User subscription information returned to the Flutter apps."""

    tier: SubscriptionTier = SubscriptionTier.FREE
    status: str = "active"
    scans_used: int = 0
    scans_limit: int = 5
    allowed_scan_types: list[str] = Field(default_factory=lambda: ["web", "github_repo"])
    expires_at: Optional[datetime] = None

    class Config:
        use_enum_values = True


class UserProfile(BaseModel):
    """User profile information."""

    uid: str
    email: Optional[EmailStr] = None
    display_name: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    subscription: SubscriptionInfo


class UpdateUserProfileRequest(BaseModel):
    """Request to update editable profile fields."""

    display_name: Optional[str] = Field(default=None, max_length=120)


class FirebaseTokenPayload(BaseModel):
    """Decoded Firebase token data."""

    uid: str
    email: Optional[EmailStr] = None
    email_verified: bool = False


class DeleteAccountRequest(BaseModel):
    """Request to delete user account."""

    confirm: bool = Field(default=False, description="Must be True to confirm deletion")
