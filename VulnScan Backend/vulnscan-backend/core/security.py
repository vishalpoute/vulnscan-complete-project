from fastapi import HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional
import firebase_admin
from firebase_admin import credentials, auth
from .config import settings


# Initialize Firebase Admin SDK
try:
    if not firebase_admin._apps:
        cred = credentials.Certificate({
            "type": "service_account",
            "project_id": settings.FIREBASE_PROJECT_ID,
            "private_key": settings.FIREBASE_PRIVATE_KEY.replace('\\n', '\n'),
            "client_email": settings.FIREBASE_CLIENT_EMAIL,
            "token_uri": "https://oauth2.googleapis.com/token",
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        })
        firebase_admin.initialize_app(cred)
        print("[OK] Firebase Admin SDK initialized successfully")
except Exception as e:
    print(f"[WARN] Firebase initialization warning: {e}")
    print("[WARN] Authentication endpoints will not work until Firebase is properly configured")


security = HTTPBearer()


async def verify_firebase_token(credentials: HTTPAuthCredentials) -> str:
    """
    Verify Firebase ID token from Authorization header.
    Returns the uid of the authenticated user.
    Raises HTTPException if token is invalid.
    """
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token.get("uid")
        if not uid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token: missing uid",
            )
        return uid
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
        )


async def verify_admin_token(credentials: HTTPAuthCredentials) -> str:
    """
    Verify Firebase ID token AND check for isAdmin custom claim.
    Returns the uid if user is admin, otherwise raises HTTPException.
    """
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token.get("uid")
        
        if not uid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token: missing uid",
            )
        
        # Check for isAdmin custom claim
        is_admin = decoded_token.get("isAdmin", False)
        if not is_admin:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin access required",
            )
        
        return uid
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
        )
