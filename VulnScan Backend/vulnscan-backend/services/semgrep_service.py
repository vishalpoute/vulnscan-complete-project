"""Semgrep security scanning wrapper."""

import subprocess
import json
from typing import List
from pathlib import Path
from models.vulnerability import Vulnerability, SeverityLevel


async def run_semgrep(repo_path: str) -> List[Vulnerability]:
    """
    Run Semgrep on the repository.
    
    Args:
        repo_path: Path to repository to scan
        
    Returns:
        List of found vulnerabilities
    """
    vulnerabilities = []
    
    try:
        # Run semgrep with auto config and JSON output
        result = subprocess.run(
            ["semgrep", "--config=auto", repo_path, "--json"],
            capture_output=True,
            text=True,
            timeout=300,  # 5 minute timeout
        )
        
        if result.returncode not in (0, 1):  # 0 = no issues, 1 = issues found
            print(f"⚠ Semgrep warning: {result.stderr}")
            return []
        
        # Parse JSON output
        try:
            data = json.loads(result.stdout)
        except json.JSONDecodeError:
            print("⚠ Semgrep: Failed to parse JSON output")
            return []
        
        # Extract results
        results = data.get("results", [])
        
        for idx, result_item in enumerate(results):
            try:
                # Extract severity and map to our enum
                semgrep_severity = result_item.get("extra", {}).get("severity", "INFO")
                severity_map = {
                    "ERROR": SeverityLevel.CRITICAL,
                    "WARNING": SeverityLevel.HIGH,
                    "INFO": SeverityLevel.MEDIUM,
                }
                severity = severity_map.get(semgrep_severity, SeverityLevel.MEDIUM)
                
                # Get code snippet from extra section
                code_snippet = result_item.get("extra", {}).get("lines", "")
                
                vuln = Vulnerability(
                    id=f"semgrep_{idx}_{result_item.get('check_id', 'unknown')}",
                    type=result_item.get("check_id", "unknown"),
                    severity=severity,
                    title=result_item.get("check_id", "Unknown"),
                    description=result_item.get("extra", {}).get("message", ""),
                    file_path=result_item.get("path", ""),
                    line_number=result_item.get("start", {}).get("line", None),
                    code_snippet=code_snippet,
                    cve_id=None,
                    tool_source="semgrep",
                )
                vulnerabilities.append(vuln)
            except Exception as e:
                print(f"⚠ Semgrep: Failed to parse result: {e}")
                continue
        
        print(f"✓ Semgrep found {len(vulnerabilities)} issues")
        return vulnerabilities
        
    except FileNotFoundError:
        print("⚠ Semgrep not installed. Install with: pip install semgrep")
        return []
    except subprocess.TimeoutExpired:
        print("⚠ Semgrep scan timed out (5 minutes)")
        return []
    except Exception as e:
        print(f"⚠ Semgrep error: {e}")
        return []
