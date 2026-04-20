"""MobSF mobile security framework wrapper."""

import aiohttp
import asyncio
import json
from pathlib import Path
from typing import List, Optional
from models.vulnerability import Vulnerability, SeverityLevel


MOBSF_API_URL = "http://localhost:8000/api"
MOBSF_UPLOAD_ENDPOINT = f"{MOBSF_API_URL}/v1/upload"
MOBSF_SCAN_ENDPOINT = f"{MOBSF_API_URL}/v1/scan"
MOBSF_REPORT_ENDPOINT = f"{MOBSF_API_URL}/v1/report"


async def run_mobsf(repo_path: str) -> List[Vulnerability]:
    """
    Run MobSF scan on Android or iOS apps.
    MobSF runs as a separate Docker service on port 8000.
    
    Args:
        repo_path: Path to repository containing APK/IPA
        
    Returns:
        List of Vulnerability objects from MobSF findings
    """
    vulnerabilities = []
    
    try:
        # Find APK or IPA files
        repo = Path(repo_path)
        apk_files = list(repo.glob("**/*.apk"))
        ipa_files = list(repo.glob("**/*.ipa"))
        
        if not apk_files and not ipa_files:
            print("⚠️ No APK or IPA files found in repository")
            return vulnerabilities
        
        # Process first APK or IPA found
        app_file = apk_files[0] if apk_files else ipa_files[0]
        print(f"📱 Found app: {app_file.name}")
        
        # Check if MobSF is running
        async with aiohttp.ClientSession() as session:
            try:
                async with session.get(f"{MOBSF_API_URL}/v1/version", timeout=aiohttp.ClientTimeout(total=5)) as resp:
                    if resp.status != 200:
                        print("⚠️ MobSF API not responding (expected on port 8000)")
                        return vulnerabilities
            except asyncio.TimeoutError:
                print("⚠️ MobSF service not running, skipping mobile scan")
                return vulnerabilities
            except Exception as e:
                print(f"⚠️ MobSF service unavailable: {e}")
                return vulnerabilities
            
            # Upload app to MobSF
            print(f"📤 Uploading {app_file.name} to MobSF...")
            with open(app_file, "rb") as f:
                form = aiohttp.FormData()
                form.add_field("file", f, filename=app_file.name)
                
                async with session.post(MOBSF_UPLOAD_ENDPOINT, data=form) as resp:
                    if resp.status != 200:
                        print(f"❌ MobSF upload failed: {resp.status}")
                        return vulnerabilities
                    
                    upload_data = await resp.json()
                    scan_hash = upload_data.get("hash")
                    
                    if not scan_hash:
                        print("❌ MobSF upload response missing hash")
                        return vulnerabilities
            
            # Start scan
            print(f"🔍 Starting MobSF scan (hash: {scan_hash[:8]}...)")
            scan_payload = {"hash": scan_hash}
            
            async with session.post(MOBSF_SCAN_ENDPOINT, json=scan_payload) as resp:
                if resp.status != 200:
                    print(f"❌ MobSF scan failed: {resp.status}")
                    return vulnerabilities
            
            # Poll for completion
            max_polls = 60  # 5 minutes at 5 sec intervals
            poll_interval = 5
            
            for poll_count in range(max_polls):
                await asyncio.sleep(poll_interval)
                
                report_payload = {"hash": scan_hash}
                async with session.post(MOBSF_REPORT_ENDPOINT, json=report_payload) as resp:
                    if resp.status != 200:
                        continue
                    
                    report_data = await resp.json()
                    
                    # Check if scan is complete
                    if report_data.get("scan_completed"):
                        print(f"✅ MobSF scan complete")
                        vulnerabilities = _parse_mobsf_report(report_data, app_file.name)
                        break
                    else:
                        progress = report_data.get("progress", 0)
                        print(f"⏳ MobSF scan progress: {progress}%")
            else:
                print("⚠️ MobSF scan timeout after 5 minutes")
        
    except Exception as e:
        print(f"❌ MobSF error: {e}")
    
    return vulnerabilities


def _parse_mobsf_report(report_data: dict, app_name: str) -> List[Vulnerability]:
    """
    Parse MobSF JSON report into Vulnerability objects.
    
    Args:
        report_data: JSON report from MobSF API
        app_name: Name of the app scanned
        
    Returns:
        List of Vulnerability objects
    """
    vulnerabilities = []
    
    # Map MobSF severity to our SeverityLevel
    severity_map = {
        "Critical": SeverityLevel.CRITICAL,
        "High": SeverityLevel.HIGH,
        "Medium": SeverityLevel.MEDIUM,
        "Low": SeverityLevel.LOW,
        "Info": SeverityLevel.INFO,
    }
    
    # Parse code issues
    code_issues = report_data.get("code_issues", {})
    for issue_type, issues in code_issues.items():
        if isinstance(issues, list):
            for issue in issues:
                severity_str = issue.get("severity", "Low")
                severity = severity_map.get(severity_str, SeverityLevel.LOW)
                
                vuln = Vulnerability(
                    id=f"mobsf_{issue_type}_{len(vulnerabilities)}",
                    type=issue_type,
                    severity=severity,
                    title=issue.get("title", issue_type),
                    description=issue.get("description", ""),
                    file_path=issue.get("file", None),
                    line_number=issue.get("line", None),
                    code_snippet=issue.get("code", None),
                    remediation=issue.get("remediation", None),
                    tool_source="mobsf",
                )
                vulnerabilities.append(vuln)
    
    # Parse manifest issues
    manifest_issues = report_data.get("manifest_issues", [])
    for issue in manifest_issues:
        severity_str = issue.get("severity", "Low")
        severity = severity_map.get(severity_str, SeverityLevel.LOW)
        
        vuln = Vulnerability(
            id=f"mobsf_manifest_{len(vulnerabilities)}",
            type="manifest_issue",
            severity=severity,
            title=issue.get("title", "Manifest Issue"),
            description=issue.get("description", ""),
            file_path="AndroidManifest.xml",
            remediation=issue.get("remediation", None),
            tool_source="mobsf",
        )
        vulnerabilities.append(vuln)
    
    # Parse certificate issues
    cert_issues = report_data.get("certificate_info", {})
    if cert_issues.get("issues"):
        for issue in cert_issues["issues"]:
            vuln = Vulnerability(
                id=f"mobsf_cert_{len(vulnerabilities)}",
                type="certificate_issue",
                severity=SeverityLevel.MEDIUM,
                title=issue.get("title", "Certificate Issue"),
                description=issue.get("description", ""),
                remediation=issue.get("remediation", None),
                tool_source="mobsf",
            )
            vulnerabilities.append(vuln)
    
    print(f"📊 MobSF found {len(vulnerabilities)} issues in {app_name}")
    return vulnerabilities
