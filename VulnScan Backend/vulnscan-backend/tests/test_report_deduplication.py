import importlib.util
from pathlib import Path
import sys
import types
import unittest
from unittest.mock import patch

models = types.ModuleType("models.vulnerability")
models.Vulnerability = types.SimpleNamespace
models.VulnerabilitySummary = lambda: types.SimpleNamespace(critical=0, high=0, medium=0, low=0, info=0, total=0)
spec = importlib.util.spec_from_file_location(
    "report_under_test", Path(__file__).parents[1] / "utils" / "report_builder.py"
)
report = importlib.util.module_from_spec(spec)
with patch.dict(sys.modules, {"models.vulnerability": models}):
    spec.loader.exec_module(report)


def finding(advisory, severity="high"):
    return types.SimpleNamespace(type="Vulnerable example", file_path="requirements.txt", line_number=None, cve_id=advisory, severity=severity, has_ai_content=False)


class ReportDeduplicationTests(unittest.TestCase):
    def test_distinct_advisories_for_one_dependency_survive(self):
        findings = report.deduplicat_vulnerabilities([finding("PYSEC-example-1"), finding("PYSEC-example-2")])
        self.assertEqual(len(findings), 2)
        self.assertEqual({v.cve_id for v in findings}, {"PYSEC-example-1", "PYSEC-example-2"})
        self.assertEqual(report.build_vulnerability_summary(findings).total, 2)

    def test_same_advisory_keeps_highest_severity(self):
        findings = report.deduplicat_vulnerabilities([finding("CVE-example", "low"), finding("CVE-example", "critical")])
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0].severity, "critical")

    def test_findings_without_advisory_keep_existing_dedup_behavior(self):
        findings = report.deduplicat_vulnerabilities([finding(None, "low"), finding(None, "high")])
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0].severity, "high")


if __name__ == "__main__":
    unittest.main()
