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
models.SeverityLevel = types.SimpleNamespace(CRITICAL="critical")
spec = importlib.util.spec_from_file_location(
    "trufflehog_under_test", Path(__file__).parents[1] / "services" / "trufflehog_service.py"
)
scanner = importlib.util.module_from_spec(spec)
with patch.dict(sys.modules, {"models.vulnerability": models}):
    spec.loader.exec_module(scanner)


class SecretRedactionTests(unittest.TestCase):
    def test_secret_characters_are_not_in_report_or_console(self):
        secret = "synthetic-private-credential-value"
        output = {"detectors": [{"raw": secret, "detector_name": "Token", "path": "fixture.txt"}]}
        result = types.SimpleNamespace(returncode=0, stdout=json.dumps(output))
        console = io.StringIO()
        with patch.object(scanner.subprocess, "run", return_value=result), contextlib.redirect_stdout(console):
            findings = asyncio.run(scanner.run_trufflehog("fixture"))
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0].code_snippet, "[REDACTED]")
        self.assertNotIn(secret[:4], repr(findings))
        self.assertNotIn(secret, console.getvalue())

    def test_json_lines_keep_all_findings_and_locations(self):
        records = [
            {"DetectorName": "ExampleToken", "DetectorType": 7, "Raw": "synthetic-secret-one", "SourceMetadata": {"Data": {"Filesystem": {"file": "one.env", "line": 3}}}},
            {"DetectorName": "ExampleKey", "DetectorType": 8, "Raw": "synthetic-secret-two", "SourceMetadata": {"Data": {"Git": {"file": "two.env", "line": 9}}}},
        ]
        output = json.dumps(records[0]) + "\n\nnot-json\n" + json.dumps(records[1])
        result = types.SimpleNamespace(returncode=0, stdout=output)
        with patch.object(scanner.subprocess, "run", return_value=result):
            findings = asyncio.run(scanner.run_trufflehog("fixture"))
        self.assertEqual(len(findings), 2)
        self.assertEqual([f.file_path for f in findings], ["one.env", "two.env"])
        self.assertEqual([f.line_number for f in findings], [3, 9])
        self.assertEqual([f.type for f in findings], ["7", "8"])
        self.assertEqual(len({f.id for f in findings}), 2)
        self.assertTrue(all(f.code_snippet == "[REDACTED]" for f in findings))
        self.assertNotIn("synthetic-secret", repr(findings))

    def test_empty_output_is_a_valid_empty_result(self):
        result = types.SimpleNamespace(returncode=0, stdout="\n  \n")
        with patch.object(scanner.subprocess, "run", return_value=result):
            self.assertEqual(asyncio.run(scanner.run_trufflehog("fixture")), [])

    def test_failure_diagnostics_do_not_expose_scanner_output(self):
        secret = "synthetic-private-credential-value"
        for kwargs in ({"return_value": types.SimpleNamespace(returncode=2, stderr=secret)}, {"side_effect": RuntimeError(secret)}):
            with self.subTest(kwargs=kwargs), patch.object(scanner.subprocess, "run", **kwargs), contextlib.redirect_stdout(io.StringIO()) as console:
                self.assertEqual(asyncio.run(scanner.run_trufflehog("fixture")), [])
                self.assertNotIn(secret, console.getvalue())


if __name__ == "__main__":
    unittest.main()
