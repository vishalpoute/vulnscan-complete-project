"""Aggregates scan tool outputs into unified report."""

from typing import List
from models.vulnerability import Vulnerability, VulnerabilitySummary


def build_vulnerability_summary(vulnerabilities: List[Vulnerability]) -> VulnerabilitySummary:
    """
    Count vulnerabilities by severity level.
    
    Args:
        vulnerabilities: List of Vulnerability objects
        
    Returns:
        VulnerabilitySummary with counts by severity
    """
    summary = VulnerabilitySummary()
    for vuln in vulnerabilities:
        if vuln.severity == "critical":
            summary.critical += 1
        elif vuln.severity == "high":
            summary.high += 1
        elif vuln.severity == "medium":
            summary.medium += 1
        elif vuln.severity == "low":
            summary.low += 1
        elif vuln.severity == "info":
            summary.info += 1
    summary.total = len(vulnerabilities)
    return summary


def deduplicat_vulnerabilities(vulnerabilities: List[Vulnerability]) -> List[Vulnerability]:
    """
    Remove duplicate vulnerabilities from multiple tools.
    Aggregates findings with same type/file/location.
    
    Args:
        vulnerabilities: List of findings from all tools
        
    Returns:
        Deduplicated list of unique findings, sorted by severity
    """
    # Create a map to track unique vulnerabilities by (type, file_path, line_number)
    unique_map = {}
    
    for vuln in vulnerabilities:
        # Use (type, file_path, line_number) as dedup key
        key = (
            vuln.type,
            vuln.file_path or "unknown",
            vuln.line_number or -1,
        )
        
        # Keep the one with highest severity if duplicates exist
        if key not in unique_map:
            unique_map[key] = vuln
        else:
            existing = unique_map[key]
            severity_rank = {
                "critical": 5,
                "high": 4,
                "medium": 3,
                "low": 2,
                "info": 1,
            }
            
            if severity_rank.get(vuln.severity, 0) > severity_rank.get(existing.severity, 0):
                unique_map[key] = vuln
    
    # Return deduplicated list, sorted by severity and AI enrichment
    result = list(unique_map.values())
    result = sort_vulnerabilities_by_priority(result)
    
    return result


def sort_vulnerabilities_by_priority(vulnerabilities: List[Vulnerability]) -> List[Vulnerability]:
    """
    Sort vulnerabilities by severity (critical → high → medium → low → info).
    Within same severity, AI-enriched vulns come first.
    
    Args:
        vulnerabilities: List of Vulnerability objects
        
    Returns:
        Sorted list of vulnerabilities
    """
    severity_order = {
        "critical": 0,
        "high": 1,
        "medium": 2,
        "low": 3,
        "info": 4,
    }
    
    # Sort by: severity (lower is higher), then by has_ai_content (True first)
    result = sorted(
        vulnerabilities,
        key=lambda x: (
            severity_order.get(x.severity, 5),
            not x.has_ai_content,  # Inverted so True comes before False
        )
    )
    
    return result
