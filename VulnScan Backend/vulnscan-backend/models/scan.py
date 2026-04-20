from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from enum import Enum
from .vulnerability import Vulnerability, VulnerabilitySummary


class ScanStatus(str, Enum):
    PENDING = "pending"
    SCANNING = "scanning"
    COMPLETED = "completed"
    FAILED = "failed"


class ScanType(str, Enum):
    WEB = "web"
    ANDROID = "android"
    IOS = "ios"
    GITHUB_REPO = "github_repo"


class CreateScanRequest(BaseModel):
    """Request to create a new scan."""

    url_or_repo: str = Field(..., description="GitHub repo URL or web URL")
    scan_type: ScanType
    target: Optional[str] = None  # specific branch/path for repos


class ScanResponse(BaseModel):
    """Response containing scan metadata."""

    id: str
    uid: str
    status: ScanStatus
    scan_type: ScanType
    url_or_repo: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ScanDetailResponse(BaseModel):
    """Detailed scan response with progress/results."""

    id: str
    uid: str
    status: ScanStatus
    scan_type: ScanType
    url_or_repo: str
    progress: int = 0  # 0-100
    created_at: datetime
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    error: Optional[str] = None

    class Config:
        from_attributes = True


class ScanReportResponse(BaseModel):
    """Full scan report with all findings."""

    id: str
    uid: str
    status: ScanStatus
    scan_type: ScanType
    url_or_repo: str
    summary: VulnerabilitySummary
    vulnerabilities: List[Vulnerability]
    created_at: datetime
    completed_at: Optional[datetime] = None
    scan_duration_seconds: Optional[int] = None

    class Config:
        from_attributes = True
