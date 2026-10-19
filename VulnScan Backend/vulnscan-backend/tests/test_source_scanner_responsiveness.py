import asyncio
import importlib.util
from pathlib import Path
import sys
import threading
import types
import unittest
from unittest.mock import patch


class SourceScannerResponsivenessTests(unittest.TestCase):
    def test_scanners_leave_event_loop_free_while_waiting(self):
        for name, output in (("semgrep", '{"results": []}'), ("trufflehog", "")):
            models = types.ModuleType("models.vulnerability")
            models.Vulnerability = types.SimpleNamespace
            models.SeverityLevel = types.SimpleNamespace()
            spec = importlib.util.spec_from_file_location(
                name + "_async_test", Path(__file__).parents[1] / "services" / (name + "_service.py")
            )
            scanner = importlib.util.module_from_spec(spec)
            with patch.dict(sys.modules, {"models.vulnerability": models}):
                spec.loader.exec_module(scanner)
            started = threading.Event()
            release = threading.Event()

            def slow_scan(*args, **kwargs):
                started.set()
                release.wait(timeout=2)
                return types.SimpleNamespace(returncode=0, stdout=output)

            async def scenario():
                task = asyncio.create_task(getattr(scanner, "run_" + name)("fixture"))
                try:
                    self.assertTrue(await asyncio.to_thread(started.wait, 1))
                    self.assertFalse(task.done())
                finally:
                    release.set()
                    self.assertEqual(await task, [])

            with self.subTest(scanner=name), patch.object(scanner.subprocess, "run", side_effect=slow_scan) as run:
                asyncio.run(scenario())
                self.assertIn("fixture", run.call_args.args[0])
                self.assertEqual(run.call_args.kwargs["timeout"], 300)


if __name__ == "__main__":
    unittest.main()
