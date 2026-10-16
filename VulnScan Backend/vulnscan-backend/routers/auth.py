from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from firebase_admin import auth as firebase_auth


router = APIRouter(prefix="/auth", tags=["auth"])


class TokenVerifyRequest(BaseModel):
    token: str


class TokenVerifyResponse(BaseModel):
    uid: str
    email: str


@router.post("/verify", response_model=TokenVerifyResponse)
async def verify_token(request: TokenVerifyRequest):
    """
    Verify Firebase ID token.
    No authentication required for this endpoint.
    """
    token = request.token.strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token is required",
        )

    try:
        decoded_token = firebase_auth.verify_id_token(token)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
        )

    uid = decoded_token.get("uid")
    email = decoded_token.get("email")
    if not uid or not email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token: missing uid or email",
        )

    return TokenVerifyResponse(uid=uid, email=email)
