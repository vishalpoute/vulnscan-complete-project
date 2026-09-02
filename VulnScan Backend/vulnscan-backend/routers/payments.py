"""Payment and subscription endpoints."""

from datetime import datetime, timedelta
import hmac
import hashlib
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from core.config import settings
from core.database import MongoDB
from core.security import security, verify_firebase_token
from models.user import ALLOWED_SCAN_TYPES, SCAN_LIMITS, SubscriptionInfo, SubscriptionTier


router = APIRouter(prefix="/payments", tags=["payments"])


class CreateOrderRequest(BaseModel):
    subscription_tier: Optional[str] = None  # pro or enterprise
    plan_id: Optional[str] = None  # Flutter client alias
    payment_method: str = "razorpay"
    amount: float = 0.0


class CreateOrderResponse(BaseModel):
    order_id: str
    upi_id: str
    amount: float
    subscription_tier: str
    created_at: datetime
    razorpay_key_id: Optional[str] = None


class VerifyPaymentRequest(BaseModel):
    order_id: str
    subscription_tier: Optional[str] = None
    plan_id: Optional[str] = None
    amount: float = 0.0
    payment_id: Optional[str] = None
    signature: Optional[str] = None


class VerifyPaymentResponse(BaseModel):
    status: str  # success or pending
    message: str
    subscription_tier: str


def _normalize_tier(subscription_tier: str | None, plan_id: str | None = None) -> SubscriptionTier:
    tier_value = subscription_tier or plan_id
    try:
        tier = SubscriptionTier(tier_value or "")
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid subscription tier. Must be: pro or enterprise",
        ) from exc

    if tier == SubscriptionTier.FREE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Free tier does not require payment",
        )
    return tier


def _verify_razorpay_signature(order_id: str, payment_id: str | None, signature: str | None) -> bool:
    """Verify Razorpay signature when the secret and gateway fields are present."""
    if not settings.RAZORPAY_KEY_SECRET:
        # Development/demo mode: no gateway secret configured.
        return True
    if not payment_id or not signature:
        return False

    payload = f"{order_id}|{payment_id}".encode()
    expected = hmac.new(
        settings.RAZORPAY_KEY_SECRET.encode(),
        payload,
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(expected, signature)


@router.post("/create-order", response_model=CreateOrderResponse)
async def create_payment_order(
    request: CreateOrderRequest,
    credentials=Depends(security),
):
    """Create a payment order for a subscription upgrade."""
    uid = await verify_firebase_token(credentials)
    tier = _normalize_tier(request.subscription_tier, request.plan_id)

    order_id = f"order_{uid}_{uuid.uuid4().hex[:10]}"
    upi_id = "9022620993@ptsbi"

    return CreateOrderResponse(
        order_id=order_id,
        upi_id=upi_id,
        amount=request.amount,
        subscription_tier=tier.value,
        created_at=datetime.utcnow(),
        razorpay_key_id=settings.RAZORPAY_KEY_ID,
    )


@router.post("/verify", response_model=VerifyPaymentResponse, include_in_schema=False)
@router.post("/verify-payment", response_model=VerifyPaymentResponse, include_in_schema=False)
@router.post("/verify-razorpay", response_model=VerifyPaymentResponse)
async def verify_payment(
    request: VerifyPaymentRequest,
    credentials=Depends(security),
):
    """Verify payment and upgrade subscription.

    If RAZORPAY_KEY_SECRET is configured, validates the Razorpay signature.
    Without it, the endpoint works in documented local/demo mode.
    """
    uid = await verify_firebase_token(credentials)
    tier = _normalize_tier(request.subscription_tier, request.plan_id)

    if not request.order_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid order ID")

    if not _verify_razorpay_signature(request.order_id, request.payment_id, request.signature):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid payment signature")

    db = MongoDB.get_db()
    await db["users"].update_one(
        {"uid": uid},
        {
            "$set": {
                "subscription_tier": tier.value,
                "scans_limit": SCAN_LIMITS[tier],
                "allowed_scan_types": ALLOWED_SCAN_TYPES[tier],
                "subscription_status": "active",
                "subscription_expires_at": datetime.utcnow() + timedelta(days=30),
                "updated_at": datetime.utcnow(),
            },
            "$setOnInsert": {
                "uid": uid,
                "scans_used": 0,
                "created_at": datetime.utcnow(),
            },
        },
        upsert=True,
    )

    return VerifyPaymentResponse(
        status="success",
        message=f"Subscription upgraded to {tier.value}",
        subscription_tier=tier.value,
    )


@router.get("/subscription-status", response_model=SubscriptionInfo)
async def get_subscription_status(credentials=Depends(security)):
    """Return the authenticated user's current subscription status."""
    uid = await verify_firebase_token(credentials)
    db = MongoDB.get_db()
    user = await db["users"].find_one({"uid": uid}) or {}
    tier = SubscriptionTier(user.get("subscription_tier", SubscriptionTier.FREE.value))
    return SubscriptionInfo(
        tier=tier,
        status=user.get("subscription_status", "active"),
        scans_used=int(user.get("scans_used", 0)),
        scans_limit=int(user.get("scans_limit", SCAN_LIMITS[tier])),
        allowed_scan_types=user.get("allowed_scan_types", ALLOWED_SCAN_TYPES[tier]),
        expires_at=user.get("subscription_expires_at"),
    )
