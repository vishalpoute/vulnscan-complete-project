import asyncio
import importlib.util
import json
from pathlib import Path
import sys
import types
import unittest
from unittest.mock import patch

# Exercise parsing without installing backend/Firebase dependencies.
models = types.ModuleType("models.vulnerability")
models.Vulnerability = types.SimpleNamespace
models.SeverityLevel = types.SimpleNamespace(CRITICAL="critical", HIGH="high", MEDIUM="medium", LOW="low")
spec = importlib.util.spec_from_file_location(
    "npm_audit_under_test", Path(__file__).parents[1] / "services" / "npm_audit_service.py"
)
audit = importlib.util.module_from_spec(spec)
with patch.dict(sys.modules, {"models.vulnerability": models}):
    spec.loader.exec_module(audit)


class NpmAuditTests(unittest.TestCase):
    def test_direct_transitive_empty_and_mixed_advisories_are_retained(self):
        fixtures = {
            "direct": {"severity": "high", "via": [{"title": "Direct issue", "cves": ["CVE-example"]}]},
            "transitive": {"severity": "moderate", "via": ["direct"]},
            "mixed": {"severity": "critical", "via": ["direct", {"title": "Mixed issue", "cves": []}]},
            "empty": {"severity": "low", "via": []},
        }
        result = types.SimpleNamespace(returncode=1, stdout=json.dumps({"vulnerabilities": fixtures}))
        with patch.object(audit.subprocess, "run", return_value=result):
            findings = asyncio.run(audit._run_npm_audit(Path("fixture")))
        self.assertEqual(len(findings), 4)
        self.assertEqual(findings[0].cve_id, "CVE-example")
        self.assertEqual(findings[1].description, "Vulnerability in dependency")
        self.assertEqual(findings[1].severity, "medium")
        self.assertEqual(findings[2].description, "Mixed issue")
        self.assertIsNone(findings[2].cve_id)
        self.assertEqual(findings[3].severity, "low")

    def test_empty_audit_returns_no_findings(self):
        result = types.SimpleNamespace(returncode=0, stdout='{"vulnerabilities": {}}')
        with patch.object(audit.subprocess, "run", return_value=result):
            self.assertEqual(asyncio.run(audit._run_npm_audit(Path("fixture"))), [])


if __name__ == "__main__":
    unittest.main()
