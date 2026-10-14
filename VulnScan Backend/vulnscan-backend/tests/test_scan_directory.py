import asyncio
import importlib.util
from pathlib import Path
import sys
import tempfile
import types
import unittest
from unittest.mock import patch

# Load the utility without requiring Firebase credentials or server dependencies.
config = types.ModuleType("core.config")
config.settings = types.SimpleNamespace(TEMP_SCAN_DIR="unused")
spec = importlib.util.spec_from_file_location(
    "cloner_under_test", Path(__file__).parents[1] / "utils" / "github_cloner.py"
)
cloner = importlib.util.module_from_spec(spec)
with patch.dict(sys.modules, {"core.config": config}):
    spec.loader.exec_module(cloner)


class ScanDirectoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        cloner.settings.TEMP_SCAN_DIR = self.temp.name

    def test_uuid_stays_inside_root(self):
        scan_id = "f47ac10b-58cc-4372-a567-0e02b2c3d479"
        self.assertEqual(cloner._scan_directory(scan_id), Path(self.temp.name).resolve() / scan_id)

    def test_invalid_ids_never_delete_or_clone(self):
        for scan_id in ("", ".", "..", "../outside", "a/b", "a\\b", "/tmp", "C:\\temp", None):
            with self.subTest(scan_id=scan_id), patch.object(cloner.shutil, "rmtree") as delete, patch.object(cloner.subprocess, "run") as run:
                with self.assertRaises(cloner.GitCloneError):
                    asyncio.run(cloner.clone_repository("https://github.com/example/repo", scan_id))
                with self.assertRaises(cloner.GitCloneError):
                    asyncio.run(cloner.cleanup_repository(scan_id))
                delete.assert_not_called()
                run.assert_not_called()

    def test_resolved_escape_rejected(self):
        with patch.object(cloner.Path, "resolve", side_effect=[Path(self.temp.name), Path(self.temp.name).parent / "outside"]):
            with self.assertRaises(cloner.GitCloneError):
                cloner._scan_directory("scan-1")

    def test_cleanup_removes_only_scan_directory(self):
        root = Path(self.temp.name)
        (root / "scan-1").mkdir()
        (root / "keep").write_text("keep")
        asyncio.run(cloner.cleanup_repository("scan-1"))
        self.assertFalse((root / "scan-1").exists())
        self.assertEqual((root / "keep").read_text(), "keep")


if __name__ == "__main__":
    unittest.main()
