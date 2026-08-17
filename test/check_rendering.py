"""Verify that render-markdown.nvim actually renders the syntax in test.md."""

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def main() -> None:
    nvim = shutil.which("nvim")
    if not nvim:
        print("FAIL  rendering - nvim executable not found in PATH")
        sys.exit(1)

    config_dir = Path(__file__).resolve().parents[1]
    env = os.environ.copy()
    env["NVIM_CONFIG_CHECKOUT"] = config_dir.as_posix()
    command = [
        nvim,
        "--headless",
        "--cmd",
        "lua vim.opt.rtp:prepend(vim.env.NVIM_CONFIG_CHECKOUT)",
        "-u",
        str(config_dir / "init.lua"),
        "-c",
        "lua dofile(vim.fs.joinpath(vim.env.NVIM_CONFIG_CHECKOUT, 'test', 'render_markdown_invariants.lua'))",
    ]

    with tempfile.TemporaryDirectory(prefix="nvim-rendering-") as cache_dir:
        env["XDG_CACHE_HOME"] = cache_dir
        try:
            result = subprocess.run(
                command,
                cwd=config_dir,
                env=env,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                timeout=330,
                check=False,
            )
        except subprocess.TimeoutExpired:
            print("FAIL  rendering - timed out")
            sys.exit(1)

    output = "\n".join(part.strip() for part in (result.stdout, result.stderr) if part.strip())
    if output:
        print(output)

    if result.returncode == 0:
        print("OK    rendering")
        sys.exit(0)

    print(f"FAIL  rendering - nvim exited with code {result.returncode}")
    sys.exit(result.returncode or 1)


if __name__ == "__main__":
    main()
