"""Check nvim plugins, LSP servers, formatters, and runtime startup."""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

# Mason LSP server name -> Mason package name
MASON_LSP_PACKAGES: dict[str, str] = {
    "pyright": "pyright",
    "ruff": "ruff",
    "ts_ls": "typescript-language-server",
    "lua_ls": "lua-language-server",
    "html": "html-lsp",
    "cssls": "css-lsp",
    "jsonls": "json-lsp",
    "yamlls": "yaml-language-server",
    "bashls": "bash-language-server",
    "dockerls": "dockerfile-language-server",
    "marksman": "marksman",
}

# Formatter name -> executable base names
FORMATTERS: dict[str, list[str]] = {
    "ruff_format": ["ruff"],
    "prettierd": ["prettierd"],
    "stylua": ["stylua"],
    "shfmt": ["shfmt"],
}


def resolve_paths() -> tuple[Path, Path]:
    """Resolve nvim config and data directory paths."""
    local_appdata = os.environ.get("LOCALAPPDATA")
    if not local_appdata:
        print("FAIL  LOCALAPPDATA env var not found")
        sys.exit(1)
    config_dir = Path(local_appdata) / "nvim"
    data_dir = Path(local_appdata) / "nvim-data"
    return config_dir, data_dir


def load_lazy_lock(config_dir: Path) -> dict[str, dict[str, str]]:
    """Load lazy-lock.json and return plugin entries."""
    lock_path = config_dir / "lazy-lock.json"
    with open(lock_path, encoding="utf-8") as f:
        return json.load(f)


def check_plugins(data_dir: Path, plugins: dict[str, dict[str, str]]) -> tuple[int, int]:
    """Check that each lazy.nvim plugin directory exists."""
    lazy_dir = data_dir / "lazy"
    ok_count = 0
    for name in sorted(plugins):
        plugin_path = lazy_dir / name
        if plugin_path.is_dir():
            print(f"  OK    {name}")
            ok_count += 1
        else:
            print(f"  FAIL  {name} - directory not found at {plugin_path}")
    return ok_count, len(plugins)


def check_mason_lsp(data_dir: Path) -> tuple[int, int]:
    """Check that each Mason LSP server package is installed."""
    packages_dir = data_dir / "mason" / "packages"
    ok_count = 0
    for lsp_name, pkg_name in sorted(MASON_LSP_PACKAGES.items()):
        pkg_path = packages_dir / pkg_name
        if pkg_path.is_dir():
            print(f"  OK    {lsp_name} ({pkg_name})")
            ok_count += 1
        else:
            print(f"  FAIL  {lsp_name} ({pkg_name}) - package not found")
    return ok_count, len(MASON_LSP_PACKAGES)


def find_executable(name: str, search_paths: list[Path]) -> str | None:
    """Search for an executable in Mason bin and system PATH."""
    candidates = [name, f"{name}.cmd", f"{name}.exe"]
    for search_path in search_paths:
        for candidate in candidates:
            full = search_path / candidate
            if full.is_file():
                return str(full)
    return shutil.which(name)


def check_formatters(data_dir: Path) -> tuple[int, int]:
    """Check that each formatter executable is available."""
    mason_bin = data_dir / "mason" / "bin"
    search_paths = [mason_bin]
    ok_count = 0
    for fmt_name, candidates in sorted(FORMATTERS.items()):
        found_path = None
        for candidate in candidates:
            found_path = find_executable(candidate, search_paths)
            if found_path:
                break
        if found_path:
            print(f"  OK    {fmt_name} ({found_path})")
            ok_count += 1
        else:
            print(f"  FAIL  {fmt_name} - not found in Mason bin or PATH")
    return ok_count, len(FORMATTERS)


def check_nvim_startup(config_dir: Path) -> tuple[int, int]:
    """Start Neovim headlessly and force-load the command-lazy Markdown plugin."""
    nvim = shutil.which("nvim")
    if not nvim:
        print("  FAIL  nvim - executable not found in PATH")
        return 0, 1

    smoke_lua = (
        "require('lazy').load({ plugins = { 'markdown-preview.nvim' } }); "
        "assert(vim.g.mkdp_auto_close == 1, 'markdown preview config was not applied')"
    )
    command = [
        nvim,
        "--headless",
        "-u",
        str(config_dir / "init.lua"),
        "-c",
        f"lua {smoke_lua}",
        "-c",
        "qa!",
    ]

    try:
        result = subprocess.run(
            command,
            cwd=config_dir,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=330,
            check=False,
        )
    except subprocess.TimeoutExpired:
        print("  FAIL  startup - timed out")
        return 0, 1

    if result.returncode == 0:
        print("  OK    startup")
        return 1, 1

    print(f"  FAIL  startup - nvim exited with code {result.returncode}")
    output = "\n".join(part.strip() for part in (result.stdout, result.stderr) if part.strip())
    if output:
        for line in output.splitlines():
            print(f"        {line}")
    return 0, 1


def main() -> None:
    config_dir, data_dir = resolve_paths()
    total_ok = 0
    total_all = 0

    print("=== lazy.nvim Plugins ===")
    plugins = load_lazy_lock(config_dir)
    ok, total = check_plugins(data_dir, plugins)
    total_ok += ok
    total_all += total
    print()

    print("=== Mason LSP Servers ===")
    ok, total = check_mason_lsp(data_dir)
    total_ok += ok
    total_all += total
    print()

    print("=== Formatters ===")
    ok, total = check_formatters(data_dir)
    total_ok += ok
    total_all += total
    print()

    print("=== Neovim Startup ===")
    ok, total = check_nvim_startup(config_dir)
    total_ok += ok
    total_all += total
    print()

    print("=== Summary ===")
    print(f"Total: {total_ok}/{total_all} OK")
    print()

    if total_ok == total_all:
        print("All checks passed.")
        sys.exit(0)

    print(f"{total_all - total_ok} check(s) failed.")
    sys.exit(1)


if __name__ == "__main__":
    main()
