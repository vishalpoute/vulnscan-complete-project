"""MobSF mobile security framework wrapper."""

import asyncio
from pathlib import Path
from typing import List

from core.config import settings
from models.vulnerability import SeverityLevel, Vulnerability


def _mobsf_endpoint(path: str) -> str:
    return f"{settings.MOBSF_API_URL.rstrip('/')}/{path.lstrip('/')}"


async def run_mobsf(repo_path: str) -> List[Vulnerability]:
    """Run MobSF scan on Android or iOS apps when MobSF is available."""
    vulnerabilities: list[Vulnerability] = []

    try:
        import aiohttp
    except ImportError:
        print("⚠️ aiohttp package is not installed, skipping MobSF scan")
        return vulnerabilities

    try:
        repo = Path(repo_path)
        apk_files = list(repo.glob("**/*.apk"))
        ipa_files = list(repo.glob("**/*.ipa"))

        if not apk_files and not ipa_files:
            print("⚠️ No APK or IPA files found in repository")
            return vulnerabilities

        app_file = apk_files[0] if apk_files else ipa_files[0]
        print(f"📱 Found app: {app_file.name}")

        headers = {"Authorization": settings.MOBSF_API_KEY} if settings.MOBSF_API_KEY else {}
        timeout = aiohttp.ClientTimeout(total=30)
        async with aiohttp.ClientSession(headers=headers, timeout=timeout) as session:
            try:
                async with session.get(_mobsf_endpoint("v1/version")) as resp:
                    if resp.status != 200:
                        print(f"⚠️ MobSF API not responding: HTTP {resp.status}")
                        return vulnerabilities
            except asyncio.TimeoutError:
                print("⚠️ MobSF service not running, skipping mobile scan")
                return vulnerabilities
            except Exception as exc:
                print(f"⚠️ MobSF service unavailable: {exc}")
                return vulnerabilities

            print(f"📤 Uploading {app_file.name} to MobSF...")
            with open(app_file, "rb") as file_handle:
                form = aiohttp.FormData()
                form.add_field("file", file_handle, filename=app_file.name)

                async with session.post(_mobsf_endpoint("v1/upload"), data=form) as resp:
                    if resp.status != 200:
                        print(f"❌ MobSF upload failed: {resp.status}")
                        return vulnerabilities

                    upload_data = await resp.json()
                    scan_hash = upload_data.get("hash")
                    if not scan_hash:
                        print("❌ MobSF upload response missing hash")
                        return vulnerabilities

            print(f"🔍 Starting MobSF scan (hash: {scan_hash[:8]}...)")
            async with session.post(_mobsf_endpoint("v1/scan"), json={"hash": scan_hash}) as resp:
                if resp.status != 200:
                    print(f"❌ MobSF scan failed: {resp.status}")
                    return vulnerabilities

            max_polls = 60  # 5 minutes at 5 sec intervals
            for _ in range(max_polls):
                await asyncio.sleep(5)

                async with session.post(_mobsf_endpoint("v1/report"), json={"hash": scan_hash}) as resp:
                    if resp.status != 200:
                        continue

                    report_data = await resp.json()
                    if report_data.get("scan_completed"):
                        print("✅ MobSF scan complete")
                        vulnerabilities = _parse_mobsf_report(report_data, app_file.name)
                        break

                    progress = report_data.get("progress", 0)
                    print(f"⏳ MobSF scan progress: {progress}%")
            else:
                print("⚠️ MobSF scan timeout after 5 minutes")

    except Exception as exc:
        print(f"❌ MobSF error: {exc}")

    return vulnerabilities


def _parse_mobsf_report(report_data: dict, app_name: str) -> List[Vulnerability]:
    """Parse MobSF JSON report into Vulnerability objects."""
    vulnerabilities: list[Vulnerability] = []
    severity_map = {
        "Critical": SeverityLevel.CRITICAL,
        "High": SeverityLevel.HIGH,
        "Medium": SeverityLevel.MEDIUM,
        "Low": SeverityLevel.LOW,
        "Info": SeverityLevel.INFO,
    }

    code_issues = report_data.get("code_issues", {})
    for issue_type, issues in code_issues.items():
        if not isinstance(issues, list):
            continue
        for issue in issues:
            severity = severity_map.get(issue.get("severity", "Low"), SeverityLevel.LOW)
            vulnerabilities.append(
                Vulnerability(
                    id=f"mobsf_{issue_type}_{len(vulnerabilities)}",
                    type=issue_type,
                    severity=severity,
                    title=issue.get("title", issue_type),
                    description=issue.get("description", ""),
                    file_path=issue.get("file"),
                    line_number=issue.get("line"),
                    code_snippet=issue.get("code"),
                    remediation=issue.get("remediation"),
                    tool_source="mobsf",
                )
            )

    for issue in report_data.get("manifest_issues", []):
        severity = severity_map.get(issue.get("severity", "Low"), SeverityLevel.LOW)
        vulnerabilities.append(
            Vulnerability(
                id=f"mobsf_manifest_{len(vulnerabilities)}",
                type="manifest_issue",
                severity=severity,
                title=issue.get("title", "Manifest Issue"),
                description=issue.get("description", ""),
                file_path="AndroidManifest.xml",
                remediation=issue.get("remediation"),
                tool_source="mobsf",
            )
        )

    cert_issues = report_data.get("certificate_info", {})
    for issue in cert_issues.get("issues", []):
        vulnerabilities.append(
            Vulnerability(
                id=f"mobsf_cert_{len(vulnerabilities)}",
                type="certificate_issue",
                severity=SeverityLevel.MEDIUM,
                title=issue.get("title", "Certificate Issue"),
                description=issue.get("description", ""),
                remediation=issue.get("remediation"),
                tool_source="mobsf",
            )
        )

    print(f"📊 MobSF found {len(vulnerabilities)} issues in {app_name}")
    return vulnerabilities
