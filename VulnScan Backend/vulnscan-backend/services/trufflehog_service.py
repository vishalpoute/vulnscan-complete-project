"""TruffleHog secret scanning wrapper."""

import subprocess
import json
from typing import List
from models.vulnerability import Vulnerability, SeverityLevel


async def run_trufflehog(repo_path: str) -> List[Vulnerability]:
    """
    Run TruffleHog to detect secrets and credentials.
    
    Args:
        repo_path: Path to repository to scan
        
    Returns:
        List of found security issues
    """
    vulnerabilities = []
    
    try:
        # Run trufflehog on filesystem with JSON output
        result = subprocess.run(
            ["trufflehog", "filesystem", repo_path, "--json"],
            capture_output=True,
            text=True,
            timeout=300,  # 5 minute timeout
        )
        
        if result.returncode not in (0, 1):
            print(f"⚠ TruffleHog warning: {result.stderr}")
            return []
        
        # Parse JSON lines output (one JSON object per line)
        try:
            for line in result.stdout.strip().split('\n'):
                if not line:
                    continue
                    
                data = json.loads(line)
        except json.JSONDecodeError:
            print("⚠ TruffleHog: Failed to parse JSON output")
            return []
        
        # Extract results from raw JSON objects
        results = data.get("detectors", [])
        if not results and "result" in data:
            # Single result format
            results = [data]
        
        for idx, result_item in enumerate(results):
            try:
                # All secrets are critical severity
                detector_name = result_item.get("detector_name", "secret")
                detector_type = result_item.get("type", "unknown")
                
                # Redact secret: show first 4 chars + ***
                raw_secret = result_item.get("raw", "")
                redacted = raw_secret[:4] + "***" if len(raw_secret) > 4 else "***"
                
                vuln = Vulnerability(
                    id=f"trufflehog_{idx}_{detector_name}",
                    type=detector_type,
                    severity=SeverityLevel.CRITICAL,
                    title=f"Detected secret: {detector_name}",
                    description=f"Potential {detector_name} detected: {redacted}",
                    file_path=result_item.get("path", ""),
                    line_number=result_item.get("line_number", None),
                    code_snippet=result_item.get("raw", "")[:50] + "..." if result_item.get("raw") else None,
                    cve_id=None,
                    tool_source="trufflehog",
                )
                vulnerabilities.append(vuln)
            except Exception as e:
                print(f"⚠ TruffleHog: Failed to parse result: {e}")
                continue
        
        print(f"✓ TruffleHog found {len(vulnerabilities)} secrets")
        return vulnerabilities
        
    except FileNotFoundError:
        print("⚠ TruffleHog not installed. Install with: pip install truffleHog")
        return []
    except subprocess.TimeoutExpired:
        print("⚠ TruffleHog scan timed out (5 minutes)")
        return []
    except Exception as e:
        print(f"⚠ TruffleHog error: {e}")
        return []
