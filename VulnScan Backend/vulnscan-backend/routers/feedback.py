"""User feedback endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status
from datetime import datetime
from core.security import verify_firebase_token, verify_admin_token, security
from core.database import MongoDB
from models.feedback import CreateFeedbackRequest, FeedbackResponse


router = APIRouter(prefix="/feedback", tags=["feedback"])


@router.post("/", response_model=dict)
async def submit_feedback(
    request: CreateFeedbackRequest,
    credentials = Depends(security),
):
    """
    Submit feedback (bug report, feature request, or general comment).
    Authenticated users only.
    """
    uid = await verify_firebase_token(credentials)
    
    # Validate rating
    if not 1 <= request.rating <= 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rating must be between 1 and 5",
        )
    
    db = MongoDB.get_db()
    feedback_collection = db["feedback"]
    
    feedback_doc = {
        "uid": uid,
        "message": request.message,
        "type": request.type.value,
        "rating": request.rating,
        "created_at": datetime.utcnow(),
        "resolved": False,
    }
    
    result = await feedback_collection.insert_one(feedback_doc)
    
    print(f"💬 Feedback submitted by {uid}: {request.type.value} (rating: {request.rating})")
    
    return {
        "id": str(result.inserted_id),
        "message": "Feedback submitted successfully. Thank you!",
    }


@router.get("/", response_model=list[FeedbackResponse])
async def list_feedback(
    credentials = Depends(security),
):
    """
    List all feedback entries (admin only).
    """
    uid = await verify_admin_token(credentials)
    
    db = MongoDB.get_db()
    feedback_collection = db["feedback"]
    
    feedback_list = await feedback_collection.find({}).sort("created_at", -1).to_list(None)
    
    result = []
    for feedback in feedback_list:
        feedback_response = FeedbackResponse(
            id=str(feedback.get("_id")),
            uid=feedback["uid"],
            message=feedback["message"],
            type=feedback["type"],
            rating=feedback["rating"],
            created_at=feedback["created_at"],
            resolved=feedback.get("resolved", False),
        )
        result.append(feedback_response)
    
    return result
