"""Regression checks for declared Mason formatter provisioning."""

import io
import os
import shutil
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

from check_setup import check_formatters


class FormatterProvisioningTests(unittest.TestCase):
    def test_package_and_launcher_are_both_required(self) -> None:
        formatter = {"name": "probe", "package": "probe-package", "executable": "probe"}
        with tempfile.TemporaryDirectory(prefix="nvim-provisioning-") as tmp:
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


if __name__ == "__main__":
    unittest.main()
