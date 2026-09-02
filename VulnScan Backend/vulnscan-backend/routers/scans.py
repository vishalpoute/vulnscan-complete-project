"""Scan creation, progress, report, and deletion endpoints."""

from datetime import datetime
import uuid

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, status

from core.database import MongoDB
from core.security import security, verify_firebase_token
from models.scan import (
    CreateScanRequest,
    ScanDetailResponse,
    ScanReportResponse,
    ScanResponse,
    ScanStatus,
    ToolProgress,
)
from services.scan_orchestrator import run_parallel_scans
from utils.github_cloner import GitCloneError, clone_repository


router = APIRouter(prefix="/scans", tags=["scans"])


TOOL_STATUS_FIELDS = {
    "semgrep": "semgrep_status",
    "trufflehog": "trufflehog_status",
    "npm_audit": "npm_audit_status",
    "mobsf": "mobsf_status",
}


def _summary_count(scan: dict, severity: str) -> int:
    summary = scan.get("summary") or {}
    return int(summary.get(severity, 0))


def _scan_response(scan: dict) -> ScanResponse:
    return ScanResponse(
        id=scan["_id"],
        uid=scan["uid"],
        status=scan.get("status", ScanStatus.PENDING.value),
        scan_type=scan.get("scan_type", "github_repo"),
        url_or_repo=scan["url_or_repo"],
        created_at=scan["created_at"],
        updated_at=scan.get("updated_at", scan["created_at"]),
        completed_at=scan.get("completed_at"),
        critical_vuln_count=_summary_count(scan, "critical"),
        high_vuln_count=_summary_count(scan, "high"),
        medium_vuln_count=_summary_count(scan, "medium"),
        low_vuln_count=_summary_count(scan, "low"),
        error_message=scan.get("error"),
    )


def _tool_progress(scan: dict) -> list[ToolProgress]:
    vulnerabilities = scan.get("vulnerabilities") or []
    progress: list[ToolProgress] = []

    for tool_name, field_name in TOOL_STATUS_FIELDS.items():
        status_value = scan.get(field_name)
        if status_value is None and tool_name == "mobsf":
            status_value = "skipped"
        elif status_value is None:
            status_value = "pending"

        progress.append(
            ToolProgress(
                tool_name=tool_name,
                status=status_value,
                vulnerabilities_found=sum(
                    1 for vuln in vulnerabilities if vuln.get("tool_source") == tool_name
                ),
                error_message=scan.get(f"{tool_name}_error"),
            )
        )

    return progress


def _scan_detail(scan: dict) -> ScanDetailResponse:
    return ScanDetailResponse(
        id=scan["_id"],
        uid=scan["uid"],
        status=scan.get("status", ScanStatus.PENDING.value),
        scan_type=scan.get("scan_type", "github_repo"),
        url_or_repo=scan["url_or_repo"],
        progress=scan.get("progress", 0),
        tool_progress=_tool_progress(scan),
        created_at=scan["created_at"],
        started_at=scan.get("started_at"),
        completed_at=scan.get("completed_at"),
        error=scan.get("error"),
    )


@router.post("/", response_model=ScanResponse, include_in_schema=False)
@router.post("", response_model=ScanResponse)
@router.post("/create", response_model=ScanResponse)
async def create_scan(
    request: CreateScanRequest,
    background_tasks: BackgroundTasks,
    credentials=Depends(security),
):
    """Create a new vulnerability scan and run it in the background."""
    uid = await verify_firebase_token(credentials)
    scan_id = str(uuid.uuid4())
    now = datetime.utcnow()

    db = MongoDB.get_db()
    scan_collection = db["scans"]

    scan_doc = {
        "_id": scan_id,
        "uid": uid,
        "status": ScanStatus.PENDING.value,
        "scan_type": request.scan_type.value,
        "url_or_repo": request.url_or_repo,
        "target": request.target,
        "created_at": now,
        "started_at": None,
        "updated_at": now,
        "progress": 0,
        "semgrep_status": "pending",
        "trufflehog_status": "pending",
        "npm_audit_status": "pending",
        "mobsf_status": "pending" if request.scan_type.value in ["android", "ios"] else "skipped",
    }

    await scan_collection.insert_one(scan_doc)
    print(f"📝 Created scan {scan_id} for user {uid}")

    background_tasks.add_task(
        _background_scan,
        scan_id=scan_id,
        uid=uid,
        repo_url=request.url_or_repo,
        scan_type=request.scan_type.value,
    )

    return _scan_response(scan_doc)


async def _background_scan(
    scan_id: str,
    uid: str,
    repo_url: str,
    scan_type: str,
) -> None:
    """Background task to clone repo and run scans."""
    db = MongoDB.get_db()
    scan_collection = db["scans"]

    try:
        print(f"📥 Cloning repository for scan {scan_id}...")
        repo_path = await clone_repository(repo_url, scan_id)

        await scan_collection.update_one(
            {"_id": scan_id, "uid": uid},
            {"$set": {"progress": 5, "updated_at": datetime.utcnow()}},
        )

        await run_parallel_scans(scan_id, repo_path, scan_type, uid)

    except GitCloneError as exc:
        print(f"❌ Clone error for scan {scan_id}: {exc}")
        await scan_collection.update_one(
            {"_id": scan_id, "uid": uid},
            {
                "$set": {
                    "status": ScanStatus.FAILED.value,
                    "error": str(exc),
                    "completed_at": datetime.utcnow(),
                    "updated_at": datetime.utcnow(),
                    "progress": 0,
                }
            },
        )
    except Exception as exc:
        print(f"❌ Unexpected error for scan {scan_id}: {exc}")
        await scan_collection.update_one(
            {"_id": scan_id, "uid": uid},
            {
                "$set": {
                    "status": ScanStatus.FAILED.value,
                    "error": str(exc),
                    "completed_at": datetime.utcnow(),
                    "updated_at": datetime.utcnow(),
                    "progress": 0,
                }
            },
        )


@router.get("/", response_model=list[ScanResponse], include_in_schema=False)
@router.get("", response_model=list[ScanResponse])
async def list_scans(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    credentials=Depends(security),
):
    """List scans for the authenticated user."""
    uid = await verify_firebase_token(credentials)

    db = MongoDB.get_db()
    scans = (
        await db["scans"]
        .find({"uid": uid})
        .sort("created_at", -1)
        .skip(offset)
        .limit(limit)
        .to_list(length=limit)
    )

    return [_scan_response(scan) for scan in scans]


@router.get("/{scan_id}", response_model=ScanDetailResponse)
@router.get("/{scan_id}/progress", response_model=ScanDetailResponse)
@router.get("/{scan_id}/status", response_model=ScanDetailResponse, include_in_schema=False)
async def get_scan_status(
    scan_id: str,
    credentials=Depends(security),
):
    """Get current status/progress for a scan."""
    uid = await verify_firebase_token(credentials)

    db = MongoDB.get_db()
    scan = await db["scans"].find_one({"_id": scan_id, "uid": uid})
    if not scan:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Scan not found")

    return _scan_detail(scan)


@router.get("/{scan_id}/report", response_model=ScanReportResponse)
async def get_scan_report(
    scan_id: str,
    credentials=Depends(security),
):
    """Get full scan report with all vulnerabilities."""
    uid = await verify_firebase_token(credentials)

    db = MongoDB.get_db()
    scan = await db["scans"].find_one({"_id": scan_id, "uid": uid})
    if not scan:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Scan not found")

    if scan.get("status") != ScanStatus.COMPLETED.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Scan is {scan.get('status', 'unknown')}, not completed",
        )

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
        summary=scan.get("summary") or {},
        vulnerabilities=scan.get("vulnerabilities") or [],
        created_at=scan["created_at"],
        completed_at=scan.get("completed_at"),
        scan_duration_seconds=scan_duration,
    )


@router.delete("/{scan_id}")
async def delete_scan(
    scan_id: str,
    credentials=Depends(security),
):
    """Delete a scan and its associated data."""
    uid = await verify_firebase_token(credentials)

    db = MongoDB.get_db()
    result = await db["scans"].delete_one({"_id": scan_id, "uid": uid})

    if result.deleted_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Scan not found")

    return {"message": "Scan deleted successfully"}
