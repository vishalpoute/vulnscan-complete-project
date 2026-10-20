import asyncio
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import sys
import types
import unittest
from unittest.mock import patch

models = types.ModuleType("models.vulnerability")
models.Vulnerability = types.SimpleNamespace
models.SeverityLevel = types.SimpleNamespace(CRITICAL="critical", HIGH="high", MEDIUM="medium")
spec = importlib.util.spec_from_file_location(
    "semgrep_under_test", Path(__file__).parents[1] / "services" / "semgrep_service.py"
)
scanner = importlib.util.module_from_spec(spec)
with patch.dict(sys.modules, {"models.vulnerability": models}):
    spec.loader.exec_module(scanner)


class SemgrepConsoleTests(unittest.TestCase):
    def test_windows_console_does_not_discard_successful_findings(self):
        result = types.SimpleNamespace(returncode=0, stdout=json.dumps({"results": [{
            "check_id": "example.rule", "path": "fixture.py", "start": {"line": 4},
            "extra": {"severity": "ERROR", "message": "Example issue", "lines": "fixture"}
        }]}))
        with io.TextIOWrapper(io.BytesIO(), encoding="cp1252", errors="strict") as console:
            with patch.object(scanner.subprocess, "run", return_value=result), contextlib.redirect_stdout(console):
                findings = asyncio.run(scanner.run_semgrep("fixture"))
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0].file_path, "fixture.py")
        self.assertEqual(findings[0].line_number, 4)
        self.assertEqual(findings[0].severity, "critical")

    def test_failure_diagnostics_do_not_expose_source_or_credentials(self):
        private = "synthetic-private-source-and-token"
        for outcome in (
            {"return_value": types.SimpleNamespace(returncode=2, stderr=private)},
            {"side_effect": RuntimeError(private)},
        ):
            with self.subTest(outcome=outcome), patch.object(scanner.subprocess, "run", **outcome), contextlib.redirect_stdout(io.StringIO()) as console:
                self.assertEqual(asyncio.run(scanner.run_semgrep("fixture")), [])
                self.assertNotIn(private, console.getvalue())
                self.assertIn("Semgrep failed", console.getvalue())

    def test_validation_failure_does_not_log_rejected_source(self):
        private = "synthetic-private-source-and-token"
        result = types.SimpleNamespace(returncode=0, stdout=json.dumps({"results": [{"extra": {"lines": private}}]}))
        with patch.object(scanner.subprocess, "run", return_value=result), patch.object(scanner, "Vulnerability", side_effect=ValueError(private)), contextlib.redirect_stdout(io.StringIO()) as console:
            self.assertEqual(asyncio.run(scanner.run_semgrep("fixture")), [])
            self.assertNotIn(private, console.getvalue())
            self.assertIn("Failed to parse result", console.getvalue())

    def test_missing_scanner_reports_failure_without_encoding_error(self):
        with io.TextIOWrapper(io.BytesIO(), encoding="cp1252", errors="strict") as console:
            with patch.object(scanner.subprocess, "run", side_effect=FileNotFoundError), contextlib.redirect_stdout(console):
                self.assertEqual(asyncio.run(scanner.run_semgrep("fixture")), [])


if __name__ == "__main__":
    unittest.main()
