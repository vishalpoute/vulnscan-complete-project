"""Admin management endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from datetime import datetime, timedelta
from core.security import verify_admin_token, security
from core.database import MongoDB
from core.firestore import FirestoreDB
from models.admin import UserInfo, ScanSummary, AnalyticsResponse, TierBreakdown, VulnBreakdown


router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/users", response_model=list[UserInfo])
async def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    credentials = Depends(security),
):
    """
    List all users with their subscription tier and scan count.
    Admin only.
    """
    uid = await verify_admin_token(credentials)
    
    db = MongoDB.get_db()
    users_collection = db["users"]
    scans_collection = db["scans"]
    
    # Fetch users
    users = await users_collection.find({}).skip(skip).limit(limit).to_list(None)
    
    result = []
    for user in users:
        # Count scans for this user
        scan_count = await scans_collection.count_documents({"uid": user["uid"]})
        
        # Get last active time
        last_scan = await scans_collection.find_one(
            {"uid": user["uid"]},
            sort=[("created_at", -1)]
        )
        last_active = last_scan.get("created_at") if last_scan else None
        
        user_info = UserInfo(
            uid=user["uid"],
            email=user.get("email"),
            subscription_tier=user.get("subscription_tier", "free"),
            scan_count=scan_count,
            last_active=last_active,
            created_at=user.get("created_at", datetime.utcnow()),
        )
        result.append(user_info)
    
    return result


@router.get("/scans", response_model=list[ScanSummary])
async def list_all_scans(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status_filter: str = Query(None),
    credentials = Depends(security),
):
    """
    List all scans across all users.
    Admin only.
    """
    uid = await verify_admin_token(credentials)
    
    db = MongoDB.get_db()
    scans_collection = db["scans"]
    
    # Build query
    query = {}
    if status_filter:
        query["status"] = status_filter
    
    # Fetch scans
    scans = await scans_collection.find(query).sort("created_at", -1).skip(skip).limit(limit).to_list(None)
    
    result = []
    for scan in scans:
        summary = scan.get("summary", {})
        scan_summary = ScanSummary(
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
        result.append(scan_summary)
    
    return result


@router.get("/analytics", response_model=AnalyticsResponse)
async def get_analytics(
    credentials = Depends(security),
):
    """
    Get system-wide analytics and metrics.
    Admin only.
    """
    uid = await verify_admin_token(credentials)
    
    db = MongoDB.get_db()
    users_collection = db["users"]
    scans_collection = db["scans"]
    
    # Total users
    total_users = await users_collection.count_documents({})
    
    # Total scans
    total_scans = await scans_collection.count_documents({})
    
    # Scans today
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    scans_today = await scans_collection.count_documents({
        "created_at": {"$gte": today_start}
    })
    
    # Tier breakdown
    all_users = await users_collection.find({}).to_list(None)
    tier_breakdown = TierBreakdown()
    for user in all_users:
        tier = user.get("subscription_tier", "free")
        if tier == "pro":
            tier_breakdown.pro += 1
        elif tier == "enterprise":
            tier_breakdown.enterprise += 1
        else:
            tier_breakdown.free += 1
    
    # Vulnerability breakdown
    all_scans = await scans_collection.find({"status": "completed"}).to_list(None)
    vuln_breakdown = VulnBreakdown()
    for scan in all_scans:
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
):
    """
    Upgrade a user to a specific tier (pro/enterprise).
    Admin operation - no authentication required for this demo.
    Updates both MongoDB and Firestore.
    """
    if tier not in ["free", "pro", "enterprise"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid tier. Must be: free, pro, or enterprise",
        )
    
    db = MongoDB.get_db()
    users_collection = db["users"]
    
    # Find user by email in MongoDB
    user = await users_collection.find_one({"email": user_email})
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with email {user_email} not found",
        )
    
    # Update MongoDB
    result = await users_collection.update_one(
        {"email": user_email},
        {
            "$set": {
                "subscription_tier": tier,
                "upgraded_at": datetime.utcnow(),
                "admin_upgraded": True,
            }
        }
    )
    
    # Update Firestore
    fs_result = await FirestoreDB.update_user_subscription(user_email, tier)
    
    print(f"✅ User {user_email} upgraded to {tier} (MongoDB: OK, Firestore: {'OK' if fs_result else 'PENDING'})")
    
    return {
        "message": f"User {user_email} upgraded to {tier} successfully",
        "email": user_email,
        "tier": tier,
        "firestore_updated": fs_result,
    }


@router.post("/reset-scans")
async def reset_user_scans(
    user_email: str = Query(..., description="User email to reset scans for"),
):
    """
    Reset scan count to 0 for a user.
    Admin operation - no authentication required for this demo.
    Updates both MongoDB and Firestore.
    """
    db = MongoDB.get_db()
    users_collection = db["users"]
    
    # Find user by email in MongoDB
    user = await users_collection.find_one({"email": user_email})
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with email {user_email} not found",
        )
    
    # Update MongoDB
    result = await users_collection.update_one(
        {"email": user_email},
        {
            "$set": {
                "scans_used": 0,
                "scans_reset_at": datetime.utcnow(),
            }
        }
    )
    
    # Update Firestore
    fs_result = await FirestoreDB.reset_user_scans(user_email)
    
    print(f"✅ Scan count reset to 0 for {user_email} (MongoDB: OK, Firestore: {'OK' if fs_result else 'PENDING'})")
    
    return {
        "message": f"Scan count reset to 0 for {user_email}",
        "email": user_email,
        "firestore_updated": fs_result,
    }


@router.delete("/users/{user_id}")
async def delete_user(
    user_id: str,
    credentials = Depends(security),
):
    """
    Delete a user account and all their associated scans.
    Admin only.
    """
    uid = await verify_admin_token(credentials)
    
    db = MongoDB.get_db()
    users_collection = db["users"]
    scans_collection = db["scans"]
    
    # Delete user
    user_result = await users_collection.delete_one({"uid": user_id})
    
    if user_result.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    
    # Delete all their scans
    scans_result = await scans_collection.delete_many({"uid": user_id})
    
    print(f"🗑️ Deleted user {user_id} and {scans_result.deleted_count} scans")
    
    return {
        "message": f"User deleted. Removed {scans_result.deleted_count} scans.",
        "user_id": user_id,
    }


@router.get("/feedback")
async def list_feedback(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    type_filter: str = Query(None),
    credentials = Depends(security),
):
    """
    List all feedback entries.
    Admin only.
    """
    uid = await verify_admin_token(credentials)
    
    db = MongoDB.get_db()
    feedback_collection = db["feedback"]
    
    # Build query
    query = {}
    if type_filter:
        query["type"] = type_filter
    
    # Fetch feedback
    feedback_list = await feedback_collection.find(query).sort("created_at", -1).skip(skip).limit(limit).to_list(None)
    
    # Convert to dict for response
    result = []
    for feedback in feedback_list:
        feedback_dict = {
            "id": str(feedback.get("_id")),
            "uid": feedback["uid"],
            "message": feedback["message"],
            "type": feedback["type"],
            "rating": feedback["rating"],
            "created_at": feedback["created_at"],
            "resolved": feedback.get("resolved", False),
        }
        result.append(feedback_dict)
    
    return result
