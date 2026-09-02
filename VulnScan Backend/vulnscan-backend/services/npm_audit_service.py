"""npm/pip dependency audit wrapper."""

import json
import subprocess
from pathlib import Path
from typing import Any, List

from models.vulnerability import SeverityLevel, Vulnerability


async def run_npm_audit(repo_path: str) -> List[Vulnerability]:
    """Run npm audit and/or Python dependency audit based on project files."""
    vulnerabilities: list[Vulnerability] = []
    project_path = Path(repo_path)

    if (project_path / "package.json").exists():
        vulnerabilities.extend(await _run_npm_audit(project_path))

    if (project_path / "requirements.txt").exists() or (project_path / "setup.py").exists() or (project_path / "pyproject.toml").exists():
        vulnerabilities.extend(await _run_pip_audit(project_path))

    return vulnerabilities


def _severity_from_string(value: str | None) -> SeverityLevel:
    severity_map = {
        "critical": SeverityLevel.CRITICAL,
        "high": SeverityLevel.HIGH,
        "moderate": SeverityLevel.MEDIUM,
        "medium": SeverityLevel.MEDIUM,
        "low": SeverityLevel.LOW,
        "info": SeverityLevel.INFO,
    }
    return severity_map.get((value or "").lower(), SeverityLevel.MEDIUM)


def _first_advisory(via: Any) -> dict[str, Any]:
    if isinstance(via, list):
        for item in via:
            if isinstance(item, dict):
                return item
    if isinstance(via, dict):
        return via
    return {}


async def _run_npm_audit(repo_path: Path) -> List[Vulnerability]:
    """Run npm audit on Node.js project."""
    vulnerabilities: list[Vulnerability] = []

    try:
        result = subprocess.run(
            ["npm", "audit", "--json"],
            cwd=str(repo_path),
            capture_output=True,
            text=True,
            timeout=120,
        )

        if result.returncode not in (0, 1):
            print(f"⚠ npm audit warning: {result.stderr}")
            return []

        try:
            data = json.loads(result.stdout or "{}")
        except json.JSONDecodeError:
            print("⚠ npm audit: Failed to parse JSON output")
            return []

        for pkg_name, vuln_data in (data.get("vulnerabilities") or {}).items():
            try:
                advisory = _first_advisory(vuln_data.get("via"))
                cves = advisory.get("cves") or advisory.get("cwe") or []
                cve_id = cves[0] if isinstance(cves, list) and cves else None
                severity = _severity_from_string(vuln_data.get("severity") or advisory.get("severity"))

                vuln = Vulnerability(
                    id=f"npm_{pkg_name}_{cve_id or advisory.get('source') or 'unknown'}",
                    type=f"Vulnerable {pkg_name}",
                    severity=severity,
                    title=advisory.get("title") or f"Vulnerable npm package: {pkg_name}",
                    description=advisory.get("title") or "Vulnerability in dependency",
                    file_path="package.json",
                    line_number=None,
                    cve_id=cve_id,
                    tool_source="npm_audit",
                )
                vulnerabilities.append(vuln)
            except Exception as exc:
                print(f"⚠ npm audit: Failed to parse vulnerability: {exc}")
                continue

        print(f"✓ npm audit found {len(vulnerabilities)} vulnerabilities")
        return vulnerabilities

    except FileNotFoundError:
        print("⚠ npm not installed. Install Node.js to enable npm scanning.")
        return []
    except subprocess.TimeoutExpired:
        print("⚠ npm audit timed out (2 minutes)")
        return []
    except Exception as exc:
        print(f"⚠ npm audit error: {exc}")
        return []


async def _run_pip_audit(repo_path: Path) -> List[Vulnerability]:
    """Run pip-audit on Python project, falling back to safety if needed."""
    vulnerabilities: list[Vulnerability] = []

    try:
        result = subprocess.run(
            ["pip-audit", "--desc", "--format", "json"],
            cwd=str(repo_path),
            capture_output=True,
            text=True,
            timeout=120,
        )

        if result.returncode not in (0, 1):
            return await _run_safety_audit(repo_path)

        try:
            data = json.loads(result.stdout or "{}")
        except json.JSONDecodeError:
            print("⚠ pip-audit: Failed to parse JSON output")
            return []

        # pip-audit v2 returns dependencies[].vulns[]. Older versions may return
        # a top-level vulnerabilities list; support both shapes.
        raw_vulnerabilities: list[dict[str, Any]] = []
        if isinstance(data.get("dependencies"), list):
            for dependency in data["dependencies"]:
                for vuln in dependency.get("vulns", []):
                    item = dict(vuln)
                    item.setdefault("name", dependency.get("name"))
                    raw_vulnerabilities.append(item)
        else:
            raw_vulnerabilities = data.get("vulnerabilities", []) or []

        for vuln_item in raw_vulnerabilities:
            try:
                package_name = vuln_item.get("name") or vuln_item.get("package") or "package"
                fix_versions = vuln_item.get("fix_versions") or []
                severity = SeverityLevel.HIGH if fix_versions else SeverityLevel.CRITICAL

                vuln = Vulnerability(
                    id=f"pip_{vuln_item.get('id', 'unknown')}_{package_name}",
                    type=f"Vulnerable {package_name}",
                    severity=severity,
                    title=f"Vulnerable pip package: {package_name}",
                    description=vuln_item.get("description", "Vulnerability in Python dependency"),
                    file_path="requirements.txt",
                    line_number=None,
                    cve_id=vuln_item.get("id"),
                    tool_source="pip_audit",
                )
                vulnerabilities.append(vuln)
            except Exception as exc:
                print(f"⚠ pip-audit: Failed to parse vulnerability: {exc}")
                continue

        print(f"✓ pip-audit found {len(vulnerabilities)} vulnerabilities")
        return vulnerabilities

    except FileNotFoundError:
        return await _run_safety_audit(repo_path)
    except subprocess.TimeoutExpired:
        print("⚠ pip-audit timed out (2 minutes)")
        return []
    except Exception as exc:
        print(f"⚠ pip-audit error: {exc}")
        return []


async def _run_safety_audit(repo_path: Path) -> List[Vulnerability]:
    """Run safety audit as fallback for Python projects."""
    vulnerabilities: list[Vulnerability] = []

    try:
        result = subprocess.run(
            ["safety", "check", "--json"],
            cwd=str(repo_path),
            capture_output=True,
            text=True,
            timeout=120,
        )

        if result.returncode not in (0, 1):
            print("⚠ safety check warning")
            return []

        try:
            data = json.loads(result.stdout or "[]")
            if isinstance(data, list):
                data = {"vulnerabilities": data}
        except json.JSONDecodeError:
            print("⚠ safety: Failed to parse JSON output")
            return []

        for vuln_item in data.get("vulnerabilities", []):
            try:
                package_name = vuln_item.get("package") or vuln_item.get("name") or "package"
                vuln = Vulnerability(
                    id=f"safety_{vuln_item.get('id', 'unknown')}_{package_name}",
                    type=f"Vulnerable {package_name}",
                    severity=SeverityLevel.HIGH,
                    title=f"Vulnerable Python package: {package_name}",
                    description=vuln_item.get("description", "Vulnerability in Python dependency"),
                    file_path="requirements.txt",
                    line_number=None,
                    cve_id=vuln_item.get("cve"),
                    tool_source="safety",
                )
                vulnerabilities.append(vuln)
            except Exception as exc:
                print(f"⚠ safety: Failed to parse vulnerability: {exc}")
                continue

        print(f"✓ safety found {len(vulnerabilities)} vulnerabilities")
        return vulnerabilities

    except FileNotFoundError:
        print("⚠ Neither pip-audit nor safety installed. Install with: pip install pip-audit")
        return []
    except subprocess.TimeoutExpired:
        print("⚠ safety check timed out (2 minutes)")
        return []
    except Exception as exc:
        print(f"⚠ safety error: {exc}")
        return []
