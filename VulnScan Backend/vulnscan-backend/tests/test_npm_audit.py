import asyncio
import contextlib
import io
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

    def test_pip_audit_nested_and_list_formats_keep_every_advisory(self):
        dependencies = [
            {"name": "example", "vulns": [
                {"id": "PYSEC-example-1", "fix_versions": ["2.0"], "description": "First issue"},
                {"id": "PYSEC-example-2", "fix_versions": [], "description": "Second issue"},
            ]},
            {"name": "clean", "vulns": []},
        ]
        for output in ({"dependencies": dependencies, "fixes": []}, dependencies):
            with self.subTest(output_type=type(output).__name__):
                result = types.SimpleNamespace(returncode=1, stdout=json.dumps(output))
                with patch.object(audit.Path, "is_file", return_value=True), patch.object(audit.subprocess, "run", return_value=result):
                    findings = asyncio.run(audit._run_pip_audit(Path("fixture")))
                self.assertEqual(len(findings), 2)
                self.assertEqual([f.cve_id for f in findings], ["PYSEC-example-1", "PYSEC-example-2"])
                self.assertTrue(all(f.title == "Vulnerable pip package: example" for f in findings))
                self.assertEqual(findings[1].description, "Second issue")

    def test_pip_audit_empty_dependencies_are_clean(self):
        result = types.SimpleNamespace(returncode=0, stdout='{"dependencies": [], "fixes": []}')
        with patch.object(audit.Path, "is_file", return_value=True), patch.object(audit.subprocess, "run", return_value=result):
            self.assertEqual(asyncio.run(audit._run_pip_audit(Path("fixture"))), [])

    def test_python_auditors_explicitly_target_repository_requirements(self):
        for runner, output in ((audit._run_pip_audit, {"dependencies": []}), (audit._run_safety_audit, {"vulnerabilities": []})):
            result = types.SimpleNamespace(returncode=0, stdout=json.dumps(output))
            with self.subTest(runner=runner.__name__), patch.object(audit.Path, "is_file", return_value=True), patch.object(audit.subprocess, "run", return_value=result) as run:
                asyncio.run(runner(Path("fixture")))
                command = run.call_args.args[0]
                self.assertEqual(command[command.index("-r") + 1], "requirements.txt")
                self.assertEqual(run.call_args.kwargs["cwd"], str(Path("fixture")))

    def test_missing_requirements_never_audits_the_host(self):
        with patch.object(audit.Path, "is_file", return_value=False), patch.object(audit.subprocess, "run") as run:
            self.assertEqual(asyncio.run(audit._run_pip_audit(Path("fixture"))), [])
            self.assertEqual(asyncio.run(audit._run_safety_audit(Path("fixture"))), [])
            run.assert_not_called()

    def test_missing_pip_audit_fallback_keeps_repository_target(self):
        result = types.SimpleNamespace(returncode=0, stdout='{"vulnerabilities": []}')
        with patch.object(audit.Path, "is_file", return_value=True), patch.object(audit.subprocess, "run", side_effect=[FileNotFoundError(), result]) as run:
            asyncio.run(audit._run_pip_audit(Path("fixture")))
            command = run.call_args.args[0]
            self.assertEqual(command[0], "safety")
            self.assertEqual(command[command.index("-r") + 1], "requirements.txt")

    def test_audit_failures_do_not_log_credentials(self):
        secret = "synthetic-registry-password"
        for runner in (audit._run_npm_audit, audit._run_pip_audit, audit._run_safety_audit):
            for outcome in (
                {"return_value": types.SimpleNamespace(returncode=2, stderr=secret)},
                {"side_effect": RuntimeError(secret)},
            ):
                with self.subTest(runner=runner.__name__, outcome=outcome), patch.object(audit.Path, "is_file", return_value=True), patch.object(audit.subprocess, "run", **outcome), contextlib.redirect_stdout(io.StringIO()) as console:
                    self.assertEqual(asyncio.run(runner(Path("fixture"))), [])
                    self.assertNotIn(secret, console.getvalue())
                    self.assertTrue(console.getvalue().strip())

    def test_model_validation_errors_do_not_log_scanner_data(self):
        secret = "synthetic-registry-password"
        cases = (
            (audit._run_npm_audit, {"vulnerabilities": {"example": {"via": []}}}),
            (audit._run_pip_audit, {"dependencies": [{"name": "example", "vulns": [{"id": "example"}]}]}),
            (audit._run_safety_audit, {"vulnerabilities": [{"package": "example"}]}),
        )
        for runner, output in cases:
            result = types.SimpleNamespace(returncode=1, stdout=json.dumps(output))
            with self.subTest(runner=runner.__name__), patch.object(audit.Path, "is_file", return_value=True), patch.object(audit.subprocess, "run", return_value=result), patch.object(audit, "Vulnerability", side_effect=ValueError(secret)), contextlib.redirect_stdout(io.StringIO()) as console:
                self.assertEqual(asyncio.run(runner(Path("fixture"))), [])
                self.assertNotIn(secret, console.getvalue())
                self.assertIn("Failed to parse vulnerability", console.getvalue())

    def test_empty_audit_returns_no_findings(self):
        result = types.SimpleNamespace(returncode=0, stdout='{"vulnerabilities": {}}')
        with patch.object(audit.subprocess, "run", return_value=result):
            self.assertEqual(asyncio.run(audit._run_npm_audit(Path("fixture"))), [])


if __name__ == "__main__":
    unittest.main()
