from fastapi import APIRouter, Depends, HTTPException, status
from core.security import verify_firebase_token, security
from models.user import SubscriptionInfo, DeleteAccountRequest
from datetime import datetime, timedelta


router = APIRouter(prefix="/user", tags=["users"])


@router.get("/subscription", response_model=SubscriptionInfo)
async def get_subscription(
    credentials = Depends(security),
):
    """
    Get user's current subscription information.
    """
    uid = await verify_firebase_token(credentials)
    
    # TODO: Fetch subscription from MongoDB
    # For now, return default FREE subscription
    return SubscriptionInfo(
        plan="free",
        status="active",
        scan_limit=5,
        scans_used=0,
        created_at=datetime.utcnow(),
        expires_at=datetime.utcnow() + timedelta(days=365),
    )


@router.delete("/account")
async def delete_account(
    request: DeleteAccountRequest,
    credentials = Depends(security),
):
    """
    Delete user account and all associated data.
    """
    uid = await verify_firebase_token(credentials)
    if not request.confirm:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Must confirm account deletion"
        )
    # TODO: Delete user from Firebase and MongoDB
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )
