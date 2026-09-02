"""Orchestrates multiple scanning tools in parallel."""

import asyncio
from datetime import datetime
from core.database import MongoDB
from models.vulnerability import SeverityLevel
from utils.github_cloner import cleanup_repository
from utils.report_builder import build_vulnerability_summary, deduplicate_vulnerabilities
from .semgrep_service import run_semgrep
from .trufflehog_service import run_trufflehog
from .npm_audit_service import run_npm_audit
from .mobsf_service import run_mobsf
from .ai_service import analyze_vulnerability


async def run_parallel_scans(
    scan_id: str,
    repo_path: str,
    scan_type: str,
    uid: str,
) -> None:
    """
    Run all applicable scanning tools in parallel.
    Updates MongoDB with results and status as they complete.
    
    Args:
        scan_id: Unique scan identifier
        repo_path: Path to cloned repository
        scan_type: Type of scan (web, github_repo, etc)
        uid: Firebase user ID
    """
    db = MongoDB.get_db()
    scan_collection = db["scans"]
    
    try:
        # Update scan status to scanning
        await scan_collection.update_one(
            {"_id": scan_id, "uid": uid},
            {
                "$set": {
                    "status": "scanning",
                    "started_at": datetime.utcnow(),
                    "progress": 10,
                    "semgrep_status": "running",
                    "trufflehog_status": "running",
                    "npm_audit_status": "running",
                }
            },
        )
        print(f"📊 Scan {scan_id}: status updated to scanning")
        
        # Prepare scanning tasks
        scan_tasks = [
            run_semgrep(repo_path),
            run_trufflehog(repo_path),
            run_npm_audit(repo_path),
        ]
        
        # Add MobSF for mobile scans
        mobsf_task_idx = None
        if scan_type in ["android", "ios"]:
            scan_tasks.append(run_mobsf(repo_path))
            mobsf_task_idx = len(scan_tasks) - 1
            print(f"📱 MobSF enabled for {scan_type} scan")
        
        # Run all tools in parallel
        results = await asyncio.gather(*scan_tasks, return_exceptions=True)
        
        semgrep_vulns = results[0] if not isinstance(results[0], Exception) else []
        trufflehog_vulns = results[1] if not isinstance(results[1], Exception) else []
        npm_vulns = results[2] if not isinstance(results[2], Exception) else []
        mobsf_vulns = []
        
        # Extract MobSF results if included
        if mobsf_task_idx is not None:
            mobsf_vulns = results[mobsf_task_idx] if not isinstance(results[mobsf_task_idx], Exception) else []
        
        # Log any exceptions
        if isinstance(results[0], Exception):
            print(f"⚠️ Semgrep error: {results[0]}")
            semgrep_vulns = []
        if isinstance(results[1], Exception):
            print(f"⚠️ TruffleHog error: {results[1]}")
            trufflehog_vulns = []
        if isinstance(results[2], Exception):
            print(f"⚠️ npm audit error: {results[2]}")
            npm_vulns = []
        if mobsf_task_idx is not None and isinstance(results[mobsf_task_idx], Exception):
            print(f"⚠️ MobSF error: {results[mobsf_task_idx]}")
            mobsf_vulns = []
        
        # Aggregate all vulnerabilities
        all_vulns = semgrep_vulns + trufflehog_vulns + npm_vulns + mobsf_vulns
        print(f"📊 Scan {scan_id}: collected {len(all_vulns)} total findings")
        
        # Deduplicate vulnerabilities
        unique_vulns = deduplicate_vulnerabilities(all_vulns)
        print(f"📊 Scan {scan_id}: {len(unique_vulns)} unique findings after deduplication")
        
        # AI enrichment for Pro/Enterprise users (only for Critical/High)
        ai_eligible_vulns = [v for v in unique_vulns if v.severity in [SeverityLevel.CRITICAL, SeverityLevel.HIGH]]
        
        if ai_eligible_vulns:
            # Check user subscription tier
            user_subscription = await _get_user_subscription(db, uid)
            if user_subscription in ["pro", "enterprise"]:
                print(f"🤖 AI enrichment enabled for {len(ai_eligible_vulns)} findings (subscription: {user_subscription})")
                
                # Analyze vulnerabilities with AI in parallel
                ai_tasks = [analyze_vulnerability(v) for v in ai_eligible_vulns]
                await asyncio.gather(*ai_tasks, return_exceptions=True)
                
                print(f"✨ AI enrichment complete for {len(ai_eligible_vulns)} findings")
            else:
                print(f"⏭️ AI enrichment skipped (subscription: {user_subscription})")
        
        # Build summary
        summary = build_vulnerability_summary(unique_vulns)
        
        # Convert vulnerabilities to dicts for MongoDB
        vuln_dicts = [v.model_dump() for v in unique_vulns]
        
        # Update scan with results
        await scan_collection.update_one(
            {"_id": scan_id, "uid": uid},
            {
                "$set": {
                    "status": "completed",
                    "completed_at": datetime.utcnow(),
                    "progress": 100,
                    "summary": summary.model_dump(),
                    "vulnerabilities": vuln_dicts,
                    "semgrep_status": "completed",
                    "trufflehog_status": "completed",
                    "npm_audit_status": "completed",
                    "mobsf_status": "completed" if mobsf_task_idx is not None else "skipped",
                }
            },
        )
        print(f"✅ Scan {scan_id}: completed successfully with {len(unique_vulns)} findings")
        
    except Exception as e:
        print(f"❌ Scan {scan_id}: failed with error: {e}")
        
        # Update scan status to failed
        await scan_collection.update_one(
            {"_id": scan_id, "uid": uid},
            {
                "$set": {
                    "status": "failed",
                    "completed_at": datetime.utcnow(),
                    "error": str(e),
                    "progress": 0,
                }
            },
        )
    
    finally:
        # Always cleanup repository
        try:
            await cleanup_repository(scan_id)
            print(f"🧹 Cleaned up temporary files for scan {scan_id}")
        except Exception as e:
            print(f"⚠️ Cleanup error for scan {scan_id}: {e}")


async def _get_user_subscription(db, uid: str) -> str:
    """
    Get user's subscription tier from MongoDB.
    
    Args:
        db: MongoDB database
        uid: Firebase user ID
        
    Returns:
        Subscription tier: "free", "pro", or "enterprise"
    """
    try:
        users_collection = db["users"]
        user = await users_collection.find_one({"uid": uid})
        
        if user:
            return user.get("subscription_tier", "free")
        
        return "free"
    except Exception as e:
        print(f"⚠️ Error fetching user subscription: {e}")
        return "free"
