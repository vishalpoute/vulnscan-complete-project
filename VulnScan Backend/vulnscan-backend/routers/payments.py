from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from core.security import verify_firebase_token, security
from datetime import datetime, timedelta
import uuid


router = APIRouter(prefix="/payments", tags=["payments"])


class CreateOrderRequest(BaseModel):
    subscription_tier: str  # 'pro' or 'enterprise'
    payment_method: str  # 'upi', 'card', 'paypal', etc
    amount: float


class CreateOrderResponse(BaseModel):
    order_id: str
    upi_id: str
    amount: float
    subscription_tier: str
    created_at: datetime


class VerifyPaymentRequest(BaseModel):
    order_id: str
    subscription_tier: str
    amount: float


class VerifyPaymentResponse(BaseModel):
    status: str  # 'success' or 'pending'
    message: str
    subscription_tier: str


@router.post("/create-order", response_model=CreateOrderResponse)
async def create_payment_order(
    request: CreateOrderRequest,
    credentials = Depends(security),
):
    """
    Create a payment order for subscription upgrade.
    """
    uid = await verify_firebase_token(credentials)
    
    # Generate order ID
    order_id = f"order_{uid}_{uuid.uuid4().hex[:8]}"
    
    # Mock UPI implementation
    upi_id = "9022620993@ptsbi"  # Your UPI ID
    
    return CreateOrderResponse(
        order_id=order_id,
        upi_id=upi_id,
        amount=request.amount,
        subscription_tier=request.subscription_tier,
        created_at=datetime.utcnow(),
    )


@router.post("/verify-payment", response_model=VerifyPaymentResponse)
async def verify_payment(
    request: VerifyPaymentRequest,
    credentials = Depends(security),
):
    """
    Verify payment and upgrade subscription.
    In production, integrate with UPI/payment gateway webhooks.
    """
    uid = await verify_firebase_token(credentials)
    
    # TODO: Actually verify payment with payment gateway
    # For demo, we accept any valid order_id
    if not request.order_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid order ID"
        )
    
    # TODO: Update subscription in MongoDB
    # db = MongoDB.get_db()
    # users_collection = db["users"]
    # await users_collection.update_one(
    #     {"_id": uid},
    #     {
    #         "$set": {
    #             "subscription.plan": request.subscription_tier,
    #             "subscription.status": "active",
    #             "subscription.expires_at": datetime.utcnow() + timedelta(days=30),
    #         }
    #     },
    # )
    
    return VerifyPaymentResponse(
        status="success",
        message=f"Subscription upgraded to {request.subscription_tier}",
        subscription_tier=request.subscription_tier,
    )
