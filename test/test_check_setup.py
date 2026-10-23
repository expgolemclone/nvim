"""Regression checks for Mason provisioning and plugin lock validation."""

import io
import os
import shutil
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

from check_setup import check_formatters, check_nvim_startup, find_nvim, load_lazy_lock


class FormatterProvisioningTests(unittest.TestCase):
    def test_package_and_launcher_are_both_required(self) -> None:
        formatter = {"name": "probe", "package": "probe-package", "executable": "probe"}
        with tempfile.TemporaryDirectory(
            prefix="nvim-provisioning-", dir="C:/dev/tmp"
        ) as tmp:
            root = Path(tmp)
            external = root / "external"
            external.mkdir()
            system_launcher = external / ("probe.exe" if os.name == "nt" else "probe")
            system_launcher.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
            system_launcher.chmod(0o755)
            data = root / "data"
            package = data / "mason" / "packages" / formatter["package"]
            mason_bin = data / "mason" / "bin"
            mason_bin.mkdir(parents=True)

            with patch.dict(os.environ, {"PATH": str(external)}):
                self.assertIsNotNone(shutil.which("probe"))
                with redirect_stdout(io.StringIO()):
                    # A PATH executable cannot satisfy either provisioning requirement.
                    self.assertEqual(check_formatters(data, [formatter]), (0, 1))
                    for suffix in ("", ".cmd", ".exe"):
                        with self.subTest(suffix=suffix):
                            launcher = mason_bin / f"probe{suffix}"
                            launcher.write_text("", encoding="utf-8")
                            self.assertEqual(
                                check_formatters(data, [formatter]), (0, 1)
                            )
                            package.mkdir(parents=True)
                            self.assertEqual(
                                check_formatters(data, [formatter]), (1, 1)
                            )
                            launcher.unlink()
                            self.assertEqual(
                                check_formatters(data, [formatter]), (0, 1)
                            )
                            package.rmdir()


class PluginLockTests(unittest.TestCase):
    def test_invalid_lock_is_rejected(self) -> None:
        root = Path(__file__).resolve().parents[1]
        nvim = find_nvim()
        lock = load_lazy_lock(root)
        cases = (
            (
                "revision",
                "Installed plugin differs from lazy-lock.json: nvim-treesitter",
            ),
            (
                "missing",
                "Configured plugin missing from lazy-lock.json: nvim-treesitter",
            ),
            ("unused", "Unused plugin in lazy-lock.json: unused-test-plugin"),
        )
        for case, message in cases:
            with self.subTest(case=case):
                invalid = {name: entry.copy() for name, entry in lock.items()}
                if case == "revision":
                    invalid["nvim-treesitter"]["commit"] = "0" * 40
                elif case == "missing":
                    del invalid["nvim-treesitter"]
                else:
                    invalid["unused-test-plugin"] = {
                        "branch": "main",
                        "commit": "0" * 40,
                    }
                output = io.StringIO()
                with (
                    patch("check_setup.load_lazy_lock", return_value=invalid),
                    redirect_stdout(output),
                ):
                    self.assertEqual(check_nvim_startup(nvim, root), (0, 1))
                self.assertIn(message, output.getvalue())


if __name__ == "__main__":
    unittest.main()
