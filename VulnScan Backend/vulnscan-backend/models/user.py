from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
from enum import Enum


class SubscriptionTier(str, Enum):
    FREE = "free"
    PRO = "pro"
    ENTERPRISE = "enterprise"


class SubscriptionInfo(BaseModel):
    """User subscription information."""

    tier: SubscriptionTier
    scans_used: int = 0
    scans_limit: int = 5  # free tier default
    expires_at: Optional[datetime] = None

    class Config:
        use_enum_values = True


class UserProfile(BaseModel):
    """User profile information."""

    uid: str
    email: EmailStr
    display_name: Optional[str] = None
    created_at: datetime
    subscription: SubscriptionInfo


class FirebaseTokenPayload(BaseModel):
    """Decoded Firebase token data."""

    uid: str
    email: Optional[EmailStr] = None
    email_verified: bool = False


class DeleteAccountRequest(BaseModel):
    """Request to delete user account."""

    confirm: bool = Field(default=False, description="Must be True to confirm deletion")
