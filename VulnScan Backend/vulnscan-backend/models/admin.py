"""Admin panel models."""

from pydantic import BaseModel
from typing import Dict, List, Optional
from datetime import datetime


class UserInfo(BaseModel):
    """User information for admin panel."""

    uid: str
    email: Optional[str] = None
    subscription_tier: str  # free, pro, enterprise
    scan_count: int = 0
    last_active: Optional[datetime] = None
    created_at: datetime


class ScanSummary(BaseModel):
    """Scan summary for admin view."""

    id: str
    uid: str
    url_or_repo: str
    status: str
    scan_type: str
    critical_count: int = 0
    high_count: int = 0
    medium_count: int = 0
    low_count: int = 0
    created_at: datetime
    completed_at: Optional[datetime] = None


class TierBreakdown(BaseModel):
    """Subscription tier breakdown."""

    free: int = 0
    pro: int = 0
    enterprise: int = 0


class VulnBreakdown(BaseModel):
    """Vulnerability severity breakdown."""

    critical: int = 0
    high: int = 0
    medium: int = 0
    low: int = 0


class AnalyticsResponse(BaseModel):
    """Admin analytics dashboard data."""

    total_users: int
    total_scans: int
    scans_today: int
    tier_breakdown: TierBreakdown
    vuln_breakdown: VulnBreakdown
