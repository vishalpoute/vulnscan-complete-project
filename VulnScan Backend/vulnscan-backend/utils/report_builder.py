"""Aggregates scan tool outputs into unified reports."""

from typing import List

from models.vulnerability import Vulnerability, VulnerabilitySummary


def _severity_value(vulnerability: Vulnerability) -> str:
    """Return severity as a plain lowercase string for sorting/counting."""
    severity = vulnerability.severity
    return getattr(severity, "value", str(severity)).lower()


def build_vulnerability_summary(vulnerabilities: List[Vulnerability]) -> VulnerabilitySummary:
    """Count vulnerabilities by severity level."""
    summary = VulnerabilitySummary()
    for vuln in vulnerabilities:
        severity = _severity_value(vuln)
        if severity == "critical":
            summary.critical += 1
        elif severity == "high":
            summary.high += 1
        elif severity == "medium":
            summary.medium += 1
        elif severity == "low":
            summary.low += 1
        elif severity == "info":
            summary.info += 1
    summary.total = len(vulnerabilities)
    return summary


def deduplicate_vulnerabilities(vulnerabilities: List[Vulnerability]) -> List[Vulnerability]:
    """Remove duplicate vulnerabilities from multiple tools.

    Findings with the same type, file path, and line number are treated as the
    same issue; the highest-severity instance is retained.
    """
    unique_map: dict[tuple[str, str, int], Vulnerability] = {}
    severity_rank = {
        "critical": 5,
        "high": 4,
        "medium": 3,
        "low": 2,
        "info": 1,
    }

    for vuln in vulnerabilities:
        key = (
            vuln.type,
            vuln.file_path or "unknown",
            vuln.line_number or -1,
        )

        if key not in unique_map:
            unique_map[key] = vuln
            continue

        existing = unique_map[key]
        if severity_rank.get(_severity_value(vuln), 0) > severity_rank.get(_severity_value(existing), 0):
            unique_map[key] = vuln

    return sort_vulnerabilities_by_priority(list(unique_map.values()))


def deduplicat_vulnerabilities(vulnerabilities: List[Vulnerability]) -> List[Vulnerability]:
    """Backward-compatible alias for the old misspelled function name."""
    return deduplicate_vulnerabilities(vulnerabilities)


def sort_vulnerabilities_by_priority(vulnerabilities: List[Vulnerability]) -> List[Vulnerability]:
    """Sort vulnerabilities by severity, then by AI enrichment."""
    severity_order = {
        "critical": 0,
        "high": 1,
        "medium": 2,
        "low": 3,
        "info": 4,
    }

    return sorted(
        vulnerabilities,
        key=lambda vuln: (
            severity_order.get(_severity_value(vuln), 5),
            not vuln.has_ai_content,
        ),
    )
