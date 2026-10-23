"""Verify retained editing features and native UI behavior."""

import os
import sys
import tempfile
from pathlib import Path

from check_setup import find_nvim, run_nvim


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    nvim = find_nvim()
    root = Path(__file__).resolve().parents[1]
    env = os.environ.copy()
    env["NVIM_CONFIG_CHECKOUT"] = root.as_posix()
    with tempfile.TemporaryDirectory(prefix="nvim-editing-", dir="C:/dev/tmp") as tmp:
        env["NVIM_TEST_TMP"] = Path(tmp).as_posix()
        for test in (
            "visual-copy.lua",
            "editing_lifecycle.lua",
            "native-enter.lua",
            "markdown-source.lua",
            "markdown-preview.lua",
        ):
            result = run_nvim(
                nvim,
                [
                    "--headless",
                    "-u",
                    str(root / "init.lua"),
                    "-c",
                    f"lua dofile('{(root / 'test' / test).as_posix()}')",
                ],
                cwd=root,
                env=env,
                timeout=90,
            )
            output = "\n".join(
                part.strip() for part in (result.stdout, result.stderr) if part.strip()
            )
            if output:
                print(output)
            if result.returncode:
                print(f"FAIL  {test} - exit {result.returncode}")
                sys.exit(result.returncode)
    print("All editing checks passed.")


if __name__ == "__main__":
    main()
