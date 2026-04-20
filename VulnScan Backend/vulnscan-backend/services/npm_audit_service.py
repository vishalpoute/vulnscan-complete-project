"""npm/pip dependency audit wrapper."""

import subprocess
import json
from typing import List
from pathlib import Path
from models.vulnerability import Vulnerability, SeverityLevel


async def run_npm_audit(repo_path: str) -> List[Vulnerability]:
    """
    Run npm audit and/or pip audit on dependencies.
    Detects project type and runs appropriate auditor.
    
    Args:
        repo_path: Path to repository to scan
        
    Returns:
        List of vulnerable dependencies
    """
    vulnerabilities = []
    repo_path = Path(repo_path)
    
    # Check for npm project (package.json)
    if (repo_path / "package.json").exists():
        vulnerabilities.extend(await _run_npm_audit(repo_path))
    
    # Check for Python project (requirements.txt or setup.py)
    if (repo_path / "requirements.txt").exists() or (repo_path / "setup.py").exists():
        vulnerabilities.extend(await _run_pip_audit(repo_path))
    
    return vulnerabilities


async def _run_npm_audit(repo_path: Path) -> List[Vulnerability]:
    """Run npm audit on Node.js project."""
    vulnerabilities = []
    
    try:
        # Run npm audit with JSON output
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
            data = json.loads(result.stdout)
        except json.JSONDecodeError:
            print("⚠ npm audit: Failed to parse JSON output")
            return []
        
        # Extract vulnerabilities from npm audit output
        vulnerabilities_dict = data.get("vulnerabilities", {})
        
        for pkg_name, vuln_data in vulnerabilities_dict.items():
            try:
                severity_str = vuln_data.get("severity", "moderate").lower()
                severity_map = {
                    "critical": SeverityLevel.CRITICAL,
                    "high": SeverityLevel.HIGH,
                    "moderate": SeverityLevel.MEDIUM,
                    "low": SeverityLevel.LOW,
                }
                severity = severity_map.get(severity_str, SeverityLevel.MEDIUM)
                
                vuln = Vulnerability(
                    id=f"npm_{pkg_name}_{vuln_data.get('via', [{}])[0].get('cves', ['unknown'])[0]}",
                    type=f"Vulnerable {pkg_name}",
                    severity=severity,
                    title=f"Vulnerable npm package: {pkg_name}",
                    description=vuln_data.get("via", [{}])[0].get("title", "Vulnerability in dependency"),
                    file_path="package.json",
                    line_number=None,
                    cve_id=vuln_data.get("via", [{}])[0].get("cves", [None])[0],
                    tool_source="npm_audit",
                )
                vulnerabilities.append(vuln)
            except Exception as e:
                print(f"⚠ npm audit: Failed to parse vulnerability: {e}")
                continue
        
        print(f"✓ npm audit found {len(vulnerabilities)} vulnerabilities")
        return vulnerabilities
        
    except FileNotFoundError:
        print("⚠ npm not installed. Install Node.js to enable npm scanning.")
        return []
    except subprocess.TimeoutExpired:
        print("⚠ npm audit timed out (2 minutes)")
        return []
    except Exception as e:
        print(f"⚠ npm audit error: {e}")
        return []


async def _run_pip_audit(repo_path: Path) -> List[Vulnerability]:
    """Run pip audit on Python project."""
    vulnerabilities = []
    
    try:
        # Run pip audit with JSON output (using safety for compatibility)
        # First try pip-audit (newer tool)
        result = subprocess.run(
            ["pip-audit", "--desc", "--format", "json"],
            cwd=str(repo_path),
            capture_output=True,
            text=True,
            timeout=120,
        )
        
        if result.returncode not in (0, 1):
            # Fallback to safety if pip-audit not available
            return await _run_safety_audit(repo_path)
        
        try:
            data = json.loads(result.stdout)
        except json.JSONDecodeError:
            print("⚠ pip-audit: Failed to parse JSON output")
            return []
        
        # Extract vulnerabilities from pip-audit output
        for vuln_item in data.get("vulnerabilities", []):
            try:
                severity_str = vuln_item.get("fix_versions", [])
                severity = SeverityLevel.HIGH if severity_str else SeverityLevel.CRITICAL
                
                vuln = Vulnerability(
                    id=f"pip_{vuln_item.get('id', 'unknown')}",
                    type=f"Vulnerable {vuln_item.get('name', 'package')}",
                    severity=severity,
                    title=f"Vulnerable pip package: {vuln_item.get('name', 'unknown')}",
                    description=vuln_item.get("description", "Vulnerability in Python dependency"),
                    file_path="requirements.txt",
                    line_number=None,
                    cve_id=vuln_item.get("id"),
                    tool_source="pip_audit",
                )
                vulnerabilities.append(vuln)
            except Exception as e:
                print(f"⚠ pip-audit: Failed to parse vulnerability: {e}")
                continue
        
        print(f"✓ pip-audit found {len(vulnerabilities)} vulnerabilities")
        return vulnerabilities
        
    except FileNotFoundError:
        return await _run_safety_audit(repo_path)
    except subprocess.TimeoutExpired:
        print("⚠ pip-audit timed out (2 minutes)")
        return []
    except Exception as e:
        print(f"⚠ pip-audit error: {e}")
        return []


async def _run_safety_audit(repo_path: Path) -> List[Vulnerability]:
    """Run safety audit as fallback for Python projects."""
    vulnerabilities = []
    
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
            data = json.loads(result.stdout)
            # Safety returns list directly
            if isinstance(data, list):
                data = {"vulnerabilities": data}
        except json.JSONDecodeError:
            print("⚠ safety: Failed to parse JSON output")
            return []
        
        for vuln_item in data.get("vulnerabilities", []):
            try:
                vuln = Vulnerability(
                    id=f"safety_{vuln_item.get('id', 'unknown')}",
                    type=f"Vulnerable {vuln_item.get('package', 'package')}",
                    severity=SeverityLevel.HIGH,
                    title=f"Vulnerable Python package: {vuln_item.get('package', 'unknown')}",
                    description=vuln_item.get("description", "Vulnerability in Python dependency"),
                    file_path="requirements.txt",
                    line_number=None,
                    cve_id=vuln_item.get("cve"),
                    tool_source="safety",
                )
                vulnerabilities.append(vuln)
            except Exception as e:
                print(f"⚠ safety: Failed to parse vulnerability: {e}")
                continue
        
        print(f"✓ safety found {len(vulnerabilities)} vulnerabilities")
        return vulnerabilities
        
    except FileNotFoundError:
        print("⚠ Neither pip-audit nor safety installed. Install with: pip install pip-audit")
        return []
    except subprocess.TimeoutExpired:
        print("⚠ safety check timed out (2 minutes)")
        return []
    except Exception as e:
        print(f"⚠ safety error: {e}")
        return []
