from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
import uuid
from datetime import datetime
from core.security import verify_firebase_token, security
from core.database import MongoDB
from models.scan import (
    CreateScanRequest,
    ScanResponse,
    ScanDetailResponse,
    ScanReportResponse,
    ScanStatus,
)
from utils.github_cloner import clone_repository, GitCloneError
from services.scan_orchestrator import run_parallel_scans


router = APIRouter(prefix="/scans", tags=["scans"])


@router.post("/", response_model=ScanResponse)
async def create_scan(
    request: CreateScanRequest,
    background_tasks: BackgroundTasks,
    credentials = Depends(security),
):
    """
    Create a new vulnerability scan.
    Requires Firebase authentication.
    Returns immediately with scan metadata.
    Scan runs in background.
    """
    uid = await verify_firebase_token(credentials)
    
    # Generate scan ID
    scan_id = str(uuid.uuid4())
    
    # Create scan document in MongoDB
    db = MongoDB.get_db()
    scan_collection = db["scans"]
    
    scan_doc = {
        "_id": scan_id,
        "uid": uid,
        "status": ScanStatus.PENDING,
        "scan_type": request.scan_type.value,
        "url_or_repo": request.url_or_repo,
        "created_at": datetime.utcnow(),
        "started_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
        "progress": 0,
    }
    
    await scan_collection.insert_one(scan_doc)
    print(f"📝 Created scan {scan_id} for user {uid}")
    
    # Schedule background task to clone and scan
    background_tasks.add_task(
        _background_scan,
        scan_id=scan_id,
        uid=uid,
        repo_url=request.url_or_repo,
        scan_type=request.scan_type.value,
    )
    
    return ScanResponse(
        id=scan_id,
        uid=uid,
        status=ScanStatus.PENDING,
        scan_type=request.scan_type,
        url_or_repo=request.url_or_repo,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )


async def _background_scan(
    scan_id: str,
    uid: str,
    repo_url: str,
    scan_type: str,
):
    """Background task to clone repo and run scans."""
    db = MongoDB.get_db()
    scan_collection = db["scans"]
    
    try:
        # Clone repository
        print(f"📥 Cloning repository for scan {scan_id}...")
        repo_path = await clone_repository(repo_url, scan_id)
        
        # Update status to cloned
        await scan_collection.update_one(
            {"_id": scan_id, "uid": uid},
            {
                "$set": {
                    "progress": 5,
                    "updated_at": datetime.utcnow(),
                }
            },
        )
        
        # Run parallel scans
        await run_parallel_scans(scan_id, repo_path, scan_type, uid)
        
    except GitCloneError as e:
        print(f"❌ Clone error for scan {scan_id}: {e}")
        await scan_collection.update_one(
            {"_id": scan_id, "uid": uid},
            {
                "$set": {
                    "status": "failed",
                    "error": str(e),
                    "completed_at": datetime.utcnow(),
                }
            },
        )
    except Exception as e:
        print(f"❌ Unexpected error for scan {scan_id}: {e}")
        await scan_collection.update_one(
            {"_id": scan_id, "uid": uid},
            {
                "$set": {
                    "status": "failed",
                    "error": str(e),
                    "completed_at": datetime.utcnow(),
                }
            },
        )


@router.get("/", response_model=list[ScanResponse])
async def list_scans(
    credentials = Depends(security),
):
    """
    List all scans for the authenticated user.
    """
    uid = await verify_firebase_token(credentials)
    
    db = MongoDB.get_db()
    scan_collection = db["scans"]
    
    # Fetch all scans for this user
    scans = await scan_collection.find({"uid": uid}).sort("created_at", -1).to_list(None)
    
    return [
        ScanResponse(
            id=scan["_id"],
            uid=scan["uid"],
            status=scan["status"],
            scan_type=scan["scan_type"],
            url_or_repo=scan["url_or_repo"],
            created_at=scan["created_at"],
            updated_at=scan["updated_at"],
        )
        for scan in scans
    ]


@router.get("/{scan_id}/status", response_model=ScanDetailResponse)
async def get_scan_status(
    scan_id: str,
    credentials = Depends(security),
):
    """
    Get current status of a scan (pending/scanning/completed/failed).
    """
    uid = await verify_firebase_token(credentials)
    
    db = MongoDB.get_db()
    scan_collection = db["scans"]
    
    scan = await scan_collection.find_one({"_id": scan_id, "uid": uid})
    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan not found",
        )
    
    return ScanDetailResponse(
        id=scan["_id"],
        uid=scan["uid"],
        status=scan.get("status", "pending"),
        scan_type=scan["scan_type"],
        url_or_repo=scan["url_or_repo"],
        progress=scan.get("progress", 0),
        created_at=scan["created_at"],
        started_at=scan.get("started_at"),
        completed_at=scan.get("completed_at"),
        error=scan.get("error"),
    )


@router.get("/{scan_id}/report", response_model=ScanReportResponse)
async def get_scan_report(
    scan_id: str,
    credentials = Depends(security),
):
    """
    Get full scan report with all vulnerabilities.
    """
    uid = await verify_firebase_token(credentials)
    
    db = MongoDB.get_db()
    scan_collection = db["scans"]
    
    scan = await scan_collection.find_one({"_id": scan_id, "uid": uid})
    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan not found",
        )
    
    if scan.get("status") != "completed":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Scan is {scan.get('status', 'unknown')}, not completed",
        )
    
    # Calculate scan duration
    scan_duration = None
    if scan.get("completed_at") and scan.get("created_at"):
        duration = scan["completed_at"] - scan["created_at"]
        scan_duration = int(duration.total_seconds())
    
    return ScanReportResponse(
        id=scan["_id"],
        uid=scan["uid"],
        status=scan["status"],
        scan_type=scan["scan_type"],
        url_or_repo=scan["url_or_repo"],
        summary=scan.get("summary", {}),
        vulnerabilities=scan.get("vulnerabilities", []),
        created_at=scan["created_at"],
        completed_at=scan.get("completed_at"),
        scan_duration_seconds=scan_duration,
    )


@router.delete("/{scan_id}")
async def delete_scan(
    scan_id: str,
    credentials = Depends(security),
):
    """
    Delete a scan and its associated data.
    """
    uid = await verify_firebase_token(credentials)
    
    db = MongoDB.get_db()
    scan_collection = db["scans"]
    
    result = await scan_collection.delete_one({"_id": scan_id, "uid": uid})
    
    if result.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan not found",
        )
    
    return {"message": "Scan deleted successfully"}
