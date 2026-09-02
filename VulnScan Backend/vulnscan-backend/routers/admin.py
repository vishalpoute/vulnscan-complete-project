"""Admin management endpoints."""

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status

from core.database import MongoDB
from core.firestore import FirestoreDB
from core.security import security, verify_admin_token
from models.admin import AnalyticsResponse, ScanSummary, TierBreakdown, UserInfo, VulnBreakdown
from models.user import ALLOWED_SCAN_TYPES, SCAN_LIMITS, SubscriptionTier


router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/users", response_model=list[UserInfo])
async def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    credentials=Depends(security),
):
    """List all users with their subscription tier and scan count. Admin only."""
    await verify_admin_token(credentials)

    db = MongoDB.get_db()
    users_collection = db["users"]
    scans_collection = db["scans"]

    users = await users_collection.find({}).skip(skip).limit(limit).to_list(length=limit)

    result: list[UserInfo] = []
    for user in users:
        uid = user["uid"]
        scan_count = await scans_collection.count_documents({"uid": uid})
        last_scan = await scans_collection.find_one({"uid": uid}, sort=[("created_at", -1)])
        result.append(
            UserInfo(
                uid=uid,
                email=user.get("email"),
                subscription_tier=user.get("subscription_tier", "free"),
                scan_count=scan_count,
                last_active=last_scan.get("created_at") if last_scan else None,
                created_at=user.get("created_at", datetime.utcnow()),
            )
        )

    return result


@router.get("/scans", response_model=list[ScanSummary])
async def list_all_scans(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status_filter: str | None = Query(default=None),
    credentials=Depends(security),
):
    """List scans across all users. Admin only."""
    await verify_admin_token(credentials)

    db = MongoDB.get_db()
    query: dict[str, str] = {}
    if status_filter:
        query["status"] = status_filter

    scans = (
        await db["scans"]
        .find(query)
        .sort("created_at", -1)
        .skip(skip)
        .limit(limit)
        .to_list(length=limit)
    )

    result: list[ScanSummary] = []
    for scan in scans:
        summary = scan.get("summary", {})
        result.append(
            ScanSummary(
                id=scan["_id"],
                uid=scan["uid"],
                url_or_repo=scan["url_or_repo"],
                status=scan.get("status", "unknown"),
                scan_type=scan.get("scan_type", "unknown"),
                critical_count=summary.get("critical", 0),
                high_count=summary.get("high", 0),
                medium_count=summary.get("medium", 0),
                low_count=summary.get("low", 0),
                created_at=scan.get("created_at", datetime.utcnow()),
                completed_at=scan.get("completed_at"),
            )
        )

    return result


@router.get("/analytics", response_model=AnalyticsResponse)
async def get_analytics(credentials=Depends(security)):
    """Get system-wide analytics and metrics. Admin only."""
    await verify_admin_token(credentials)

    db = MongoDB.get_db()
    users_collection = db["users"]
    scans_collection = db["scans"]

    total_users = await users_collection.count_documents({})
    total_scans = await scans_collection.count_documents({})
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    scans_today = await scans_collection.count_documents({"created_at": {"$gte": today_start}})

    tier_breakdown = TierBreakdown()
    for user in await users_collection.find({}).to_list(length=None):
        tier = user.get("subscription_tier", "free")
        if tier == "pro":
            tier_breakdown.pro += 1
        elif tier == "enterprise":
            tier_breakdown.enterprise += 1
        else:
            tier_breakdown.free += 1

    vuln_breakdown = VulnBreakdown()
    for scan in await scans_collection.find({"status": "completed"}).to_list(length=None):
        summary = scan.get("summary", {})
        vuln_breakdown.critical += summary.get("critical", 0)
        vuln_breakdown.high += summary.get("high", 0)
        vuln_breakdown.medium += summary.get("medium", 0)
        vuln_breakdown.low += summary.get("low", 0)

    return AnalyticsResponse(
        total_users=total_users,
        total_scans=total_scans,
        scans_today=scans_today,
        tier_breakdown=tier_breakdown,
        vuln_breakdown=vuln_breakdown,
    )


@router.post("/upgrade-user")
async def upgrade_user(
    user_email: str = Query(..., description="User email to upgrade"),
    tier: str = Query(..., description="Target tier: free, pro, or enterprise"),
    credentials=Depends(security),
):
    """Upgrade a user tier in MongoDB and Firestore. Admin only."""
    await verify_admin_token(credentials)

    try:
        subscription_tier = SubscriptionTier(tier)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid tier. Must be: free, pro, or enterprise",
        ) from exc

    db = MongoDB.get_db()
    users_collection = db["users"]
    user = await users_collection.find_one({"email": user_email})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with email {user_email} not found",
        )

    await users_collection.update_one(
        {"email": user_email},
        {
            "$set": {
                "subscription_tier": subscription_tier.value,
                "scans_limit": SCAN_LIMITS[subscription_tier],
                "allowed_scan_types": ALLOWED_SCAN_TYPES[subscription_tier],
                "upgraded_at": datetime.utcnow(),
                "admin_upgraded": True,
                "updated_at": datetime.utcnow(),
            }
        },
    )

    fs_result = await FirestoreDB.update_user_subscription(user_email, subscription_tier.value)
    return {
        "message": f"User {user_email} upgraded to {subscription_tier.value} successfully",
        "email": user_email,
        "tier": subscription_tier.value,
        "firestore_updated": fs_result,
    }


@router.post("/reset-scans")
async def reset_user_scans(
    user_email: str = Query(..., description="User email to reset scans for"),
    credentials=Depends(security),
):
    """Reset scan count to 0 for a user. Admin only."""
    await verify_admin_token(credentials)

    db = MongoDB.get_db()
    users_collection = db["users"]
    user = await users_collection.find_one({"email": user_email})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with email {user_email} not found",
        )

    await users_collection.update_one(
        {"email": user_email},
        {
            "$set": {
                "scans_used": 0,
                "scans_reset_at": datetime.utcnow(),
                "updated_at": datetime.utcnow(),
            }
        },
    )

    fs_result = await FirestoreDB.reset_user_scans(user_email)
    return {
        "message": f"Scan count reset to 0 for {user_email}",
        "email": user_email,
        "firestore_updated": fs_result,
    }


@router.delete("/users/{user_id}")
async def delete_user(user_id: str, credentials=Depends(security)):
    """Delete a user account and all associated scans. Admin only."""
    await verify_admin_token(credentials)

    db = MongoDB.get_db()
    user_result = await db["users"].delete_one({"uid": user_id})
    if user_result.deleted_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    scans_result = await db["scans"].delete_many({"uid": user_id})
    print(f"🗑️ Deleted user {user_id} and {scans_result.deleted_count} scans")
    return {
        "message": f"User deleted. Removed {scans_result.deleted_count} scans.",
        "user_id": user_id,
    }


@router.get("/feedback")
async def list_feedback(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    type_filter: str | None = Query(default=None),
    credentials=Depends(security),
):
    """List all feedback entries. Admin only."""
    await verify_admin_token(credentials)

    db = MongoDB.get_db()
    query: dict[str, str] = {}
    if type_filter:
        query["type"] = type_filter

    feedback_list = (
        await db["feedback"]
        .find(query)
        .sort("created_at", -1)
        .skip(skip)
        .limit(limit)
        .to_list(length=limit)
    )

    return [
        {
            "id": str(feedback.get("_id")),
            "uid": feedback["uid"],
            "message": feedback["message"],
            "type": feedback["type"],
            "rating": feedback["rating"],
            "created_at": feedback["created_at"],
            "resolved": feedback.get("resolved", False),
        }
        for feedback in feedback_list
    ]
