"""Feedback model for user submissions."""

from pydantic import BaseModel
from datetime import datetime
from enum import Enum
from typing import Optional


class FeedbackType(str, Enum):
    BUG = "bug"
    FEATURE = "feature"
    GENERAL = "general"


class CreateFeedbackRequest(BaseModel):
    """Request to submit feedback."""

    message: str
    type: FeedbackType
    rating: int  # 1-5


class FeedbackResponse(BaseModel):
    """Feedback response with metadata."""

    id: Optional[str] = None
    uid: str
    message: str
    type: FeedbackType
    rating: int
    created_at: datetime
    resolved: bool = False

    class Config:
        from_attributes = True
