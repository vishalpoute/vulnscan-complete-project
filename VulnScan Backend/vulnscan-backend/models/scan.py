from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import AliasChoices, BaseModel, Field

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

    url_or_repo: str = Field(
        ...,
        description="GitHub repository URL or web URL",
        validation_alias=AliasChoices("url_or_repo", "url", "repository_url"),
    )
    scan_type: ScanType = ScanType.GITHUB_REPO
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
    completed_at: Optional[datetime] = None
    critical_vuln_count: int = 0
    high_vuln_count: int = 0
    medium_vuln_count: int = 0
    low_vuln_count: int = 0
    error_message: Optional[str] = None

    class Config:
        from_attributes = True
        use_enum_values = True


class ToolProgress(BaseModel):
    """Progress for one scanner tool."""

    tool_name: str
    status: str = "pending"
    error_message: Optional[str] = None
    vulnerabilities_found: int = 0


class ScanDetailResponse(BaseModel):
    """Detailed scan response with progress/results."""

    id: str
    uid: str
    status: ScanStatus
    scan_type: ScanType
    url_or_repo: str
    progress: int = 0  # 0-100
    tool_progress: List[ToolProgress] = Field(default_factory=list)
    created_at: datetime
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    error: Optional[str] = None

    class Config:
        from_attributes = True
        use_enum_values = True


class ScanReportResponse(BaseModel):
    """Full scan report with all findings."""

    id: str
    uid: str
    status: ScanStatus
    scan_type: ScanType
    url_or_repo: str
    summary: VulnerabilitySummary = Field(default_factory=VulnerabilitySummary)
    vulnerabilities: List[Vulnerability] = Field(default_factory=list)
    created_at: datetime
    completed_at: Optional[datetime] = None
    scan_duration_seconds: Optional[int] = None

    class Config:
        from_attributes = True
        use_enum_values = True
