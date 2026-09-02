"""TruffleHog secret scanning wrapper."""

import json
import subprocess
from typing import Any, List

from models.vulnerability import SeverityLevel, Vulnerability


def _filesystem_metadata(result_item: dict[str, Any]) -> dict[str, Any]:
    source_metadata = result_item.get("SourceMetadata") or result_item.get("source_metadata") or {}
    data = source_metadata.get("Data") or source_metadata.get("data") or {}
    return data.get("Filesystem") or data.get("filesystem") or {}


async def run_trufflehog(repo_path: str) -> List[Vulnerability]:
    """Run TruffleHog to detect secrets and credentials."""
    vulnerabilities: list[Vulnerability] = []

    try:
        result = subprocess.run(
            ["trufflehog", "filesystem", repo_path, "--json"],
            capture_output=True,
            text=True,
            timeout=300,
        )

        if result.returncode not in (0, 1):
            print(f"⚠ TruffleHog warning: {result.stderr}")
            return []

        findings: list[dict[str, Any]] = []
        for line in result.stdout.splitlines():
            if not line.strip():
                continue
            try:
                parsed = json.loads(line)
                if isinstance(parsed, dict):
                    findings.append(parsed)
            except json.JSONDecodeError as exc:
                print(f"⚠ TruffleHog: skipped invalid JSON line: {exc}")

        for idx, result_item in enumerate(findings):
            try:
                detector_name = (
                    result_item.get("DetectorName")
                    or result_item.get("detector_name")
                    or result_item.get("detectorName")
                    or "secret"
                )
                detector_type = (
                    result_item.get("DetectorType")
                    or result_item.get("type")
                    or result_item.get("detector_type")
                    or "secret"
                )
                raw_secret = result_item.get("Raw") or result_item.get("raw") or ""
                redacted = raw_secret[:4] + "***" if len(raw_secret) > 4 else "***"
                filesystem = _filesystem_metadata(result_item)

                vuln = Vulnerability(
                    id=f"trufflehog_{idx}_{detector_name}",
                    type=str(detector_type),
                    severity=SeverityLevel.CRITICAL,
                    title=f"Detected secret: {detector_name}",
                    description=f"Potential {detector_name} detected: {redacted}",
                    file_path=(
                        result_item.get("path")
                        or result_item.get("Path")
                        or filesystem.get("file")
                        or filesystem.get("File")
                    ),
                    line_number=(
                        result_item.get("line_number")
                        or result_item.get("Line")
                        or filesystem.get("line")
                        or filesystem.get("Line")
                    ),
                    code_snippet=(raw_secret[:50] + "...") if raw_secret else None,
                    cve_id=None,
                    tool_source="trufflehog",
                )
                vulnerabilities.append(vuln)
            except Exception as exc:
                print(f"⚠ TruffleHog: Failed to parse result: {exc}")
                continue

        print(f"✓ TruffleHog found {len(vulnerabilities)} secrets")
        return vulnerabilities

    except FileNotFoundError:
        print("⚠ TruffleHog not installed. Install it to enable secret scanning.")
        return []
    except subprocess.TimeoutExpired:
        print("⚠ TruffleHog scan timed out (5 minutes)")
        return []
    except Exception as exc:
        print(f"⚠ TruffleHog error: {exc}")
        return []
