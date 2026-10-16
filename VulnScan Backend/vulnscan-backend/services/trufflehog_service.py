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
            print(f"TruffleHog failed (exit code {result.returncode})")
            return []
        
        # TruffleHog emits one finding per JSON line, using PascalCase fields.
        # Keep support for the legacy detector-list format as well.
        results = []
        for line in result.stdout.splitlines():
            if not line.strip():
                continue
            try:
                data = json.loads(line)
            except json.JSONDecodeError:
                print("TruffleHog: Skipping malformed JSON line")
                continue
            if not isinstance(data, dict):
                continue
            if isinstance(data.get("detectors"), list):
                results.extend(item for item in data["detectors"] if isinstance(item, dict))
            elif "DetectorName" in data or "detector_name" in data or "result" in data:
                results.append(data)

        for idx, result_item in enumerate(results):
            try:
                # All secrets are critical severity
                detector_name = result_item.get("DetectorName", result_item.get("detector_name", "secret"))
                detector_type = str(result_item.get("DetectorType", result_item.get("type", "unknown")))
                source_data = result_item.get("SourceMetadata", {}).get("Data", {})
                location = source_data.get("Filesystem", source_data.get("Git", {}))
                
                # Reports must not persist any raw credential characters.
                redacted = "[REDACTED]"
                
                vuln = Vulnerability(
                    id=f"trufflehog_{idx}_{detector_name}",
                    type=detector_type,
                    severity=SeverityLevel.CRITICAL,
                    title=f"Detected secret: {detector_name}",
                    description=f"Potential {detector_name} detected: {redacted}",
                    file_path=location.get("file", result_item.get("path", "")),
                    line_number=location.get("line", result_item.get("line_number", None)),
                    code_snippet=redacted if result_item.get("Raw", result_item.get("raw")) else None,
                    cve_id=None,
                    tool_source="trufflehog",
                )
                vulnerabilities.append(vuln)
            except Exception as e:
                print("TruffleHog: Failed to parse result")
                continue
        
        print(f"TruffleHog found {len(vulnerabilities)} secrets")
        return vulnerabilities
        
    except FileNotFoundError:
        print("TruffleHog not installed. Install with: pip install truffleHog")
        return []
    except subprocess.TimeoutExpired:
        print("TruffleHog scan timed out (5 minutes)")
        return []
    except Exception as e:
        print("TruffleHog scan failed")
        return []
