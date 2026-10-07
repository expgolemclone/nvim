"""Check nvim plugins, LSP servers, formatters, and runtime startup."""

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


def find_nvim() -> str:
    """Find the Neovim executable."""
    nvim = shutil.which("nvim")
    if not nvim:
        print("FAIL  nvim - executable not found in PATH")
        sys.exit(1)
    return nvim


def run_nvim(
    nvim: str,
    args: list[str],
    *,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    timeout: int = 30,
) -> subprocess.CompletedProcess[str]:
    """Run Neovim with UTF-8 output handling."""
    return subprocess.run(
        [nvim, *args],
        cwd=cwd,
        env=env,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
        check=False,
    )


def resolve_paths(nvim: str) -> tuple[Path, Path]:
    """Resolve the checkout root and Neovim data directory."""
    config_dir = Path(__file__).resolve().parents[1]
    result = run_nvim(
        nvim,
        [
            "--headless",
            "-u",
            "NONE",
            "-c",
            "lua io.write(vim.fn.stdpath('data'))",
            "-c",
            "qa!",
        ],
    )
    if result.returncode != 0 or not result.stdout.strip():
        print("FAIL  unable to resolve Neovim data directory")
        output = "\n".join(
            part.strip() for part in (result.stdout, result.stderr) if part.strip()
        )
        if output:
            for line in output.splitlines():
                print(f"      {line}")
        sys.exit(1)

    return config_dir, Path(result.stdout.strip())


def load_tooling(nvim: str, config_dir: Path) -> dict[str, Any]:
    """Load tooling metadata from the same Lua module used by the config."""
    env = os.environ.copy()
    env["NVIM_TOOLING_LUA"] = (config_dir / "lua").as_posix()
    result = run_nvim(
        nvim,
        [
            "--headless",
            "-u",
            "NONE",
            "-c",
            (
                "lua package.path = vim.env.NVIM_TOOLING_LUA .. '/?.lua;' .. package.path; "
                "io.write(vim.json.encode(require('tooling')))"
            ),
            "-c",
            "qa!",
        ],
        env=env,
    )
    if result.returncode != 0:
        print("FAIL  unable to load lua/tooling.lua")
        output = "\n".join(
            part.strip() for part in (result.stdout, result.stderr) if part.strip()
        )
        if output:
            for line in output.splitlines():
                print(f"      {line}")
        sys.exit(1)

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        print(f"FAIL  invalid tooling metadata: {exc}")
        sys.exit(1)


def load_lazy_lock(config_dir: Path) -> dict[str, dict[str, str]]:
    """Load lazy-lock.json and return plugin entries."""
    lock_path = config_dir / "lazy-lock.json"
    with open(lock_path, encoding="utf-8") as f:
        return json.load(f)


def plugin_commit(plugin_path: Path) -> str:
    """Resolve a plugin's full commit from loose or packed repository refs."""
    metadata = plugin_path / ".git"
    head = (metadata / "HEAD").read_text(encoding="utf-8").strip()
    if not head.startswith("ref: "):
        return head
    ref = head.removeprefix("ref: ")
    loose_ref = metadata / ref
    if loose_ref.is_file():
        return loose_ref.read_text(encoding="utf-8").strip()
    for line in (metadata / "packed-refs").read_text(encoding="utf-8").splitlines():
        commit, _, name = line.partition(" ")
        if name == ref:
            return commit
    raise ValueError(f"unresolved repository ref: {ref}")


def check_plugins(
    data_dir: Path, plugins: dict[str, dict[str, str]]
) -> tuple[int, int]:
    """Check that installed plugins exactly match their locked commits."""
    lazy_dir = data_dir / "lazy"
    ok_count = 0
    for name in sorted(plugins):
        plugin_path = lazy_dir / name
        if not plugin_path.is_dir():
            print(f"  FAIL  {name} - directory not found at {plugin_path}")
            continue
        try:
            commit = plugin_commit(plugin_path)
        except (OSError, ValueError) as exc:
            print(f"  FAIL  {name} - cannot resolve installed commit: {exc}")
            continue
        expected = plugins[name]["commit"]
        if commit != expected:
            print(f"  FAIL  {name} - installed {commit}, locked {expected}")
            continue
        print(f"  OK    {name}")
        ok_count += 1
    return ok_count, len(plugins)


def check_mason_lsp(
    data_dir: Path, lsp_servers: list[dict[str, str]]
) -> tuple[int, int]:
    """Check that every configured Mason LSP package is installed."""
    packages_dir = data_dir / "mason" / "packages"
    ok_count = 0
    for server in sorted(lsp_servers, key=lambda item: item["name"]):
        lsp_name = server["name"]
        pkg_name = server["package"]
        pkg_path = packages_dir / pkg_name
        if pkg_path.is_dir():
            print(f"  OK    {lsp_name} ({pkg_name})")
            ok_count += 1
        else:
            print(f"  FAIL  {lsp_name} ({pkg_name}) - package not found")
    return ok_count, len(lsp_servers)


def find_executable(name: str, search_paths: list[Path]) -> str | None:
    """Search for an executable in Mason bin and system PATH."""
    candidates = [name, f"{name}.cmd", f"{name}.exe"]
    for search_path in search_paths:
        for candidate in candidates:
            full = search_path / candidate
            if full.is_file():
                return str(full)
    return shutil.which(name)


def check_formatters(
    data_dir: Path, formatters: list[dict[str, str]]
) -> tuple[int, int]:
    """Check that every configured formatter executable is available."""
    mason_bin = data_dir / "mason" / "bin"
    search_paths = [mason_bin]
    ok_count = 0
    for formatter in sorted(formatters, key=lambda item: item["name"]):
        fmt_name = formatter["name"]
        executable = formatter["executable"]
        found_path = find_executable(executable, search_paths)
        if found_path:
            print(f"  OK    {fmt_name} ({found_path})")
            ok_count += 1
        else:
            print(f"  FAIL  {fmt_name} - {executable} not found in Mason bin or PATH")
    return ok_count, len(formatters)


def check_nvim_startup(nvim: str, config_dir: Path) -> tuple[int, int]:
    """Check startup, Markdown preview, and displayed line-ending labels."""
    smoke_lua = (
        "local config = require('lazy.core.config'); "
        "assert(vim.fs.normalize(config.options.lockfile) == "
        "vim.fs.normalize(vim.fs.joinpath(vim.env.NVIM_CONFIG_CHECKOUT, 'lazy-lock.json')), "
        "'lazy.nvim must use the checkout lockfile'); "
        "local lock = vim.json.decode(vim.env.NVIM_LOCK_JSON); "
        "for name in pairs(config.plugins) do "
        "assert(lock[name], 'Configured plugin missing from lazy-lock.json: ' .. name) end; "
        "require('lazy').load({ plugins = { 'markdown-preview.nvim' } }); "
        "assert(vim.g.mkdp_auto_close == 1, 'markdown preview config was not applied'); "
        "dofile(vim.fs.joinpath(vim.env.NVIM_CONFIG_CHECKOUT, 'test', 'statusline_fileformat.lua')); "
        "dofile(vim.fs.joinpath(vim.env.NVIM_CONFIG_CHECKOUT, 'test', 'message_fileformat.lua'))"
    )
    env = os.environ.copy()
    env["NVIM_CONFIG_CHECKOUT"] = config_dir.as_posix()
    # Capture the lock before lazy.nvim can rewrite it during startup.
    env["NVIM_LOCK_JSON"] = json.dumps(load_lazy_lock(config_dir))
    command = [
        "--headless",
        "--cmd",
        "lua vim.opt.rtp:prepend(vim.env.NVIM_CONFIG_CHECKOUT)",
        "-u",
        str(config_dir / "init.lua"),
        "-c",
        (
            f"lua vim.schedule(function() local ok, err = xpcall(function() {smoke_lua} end, debug.traceback); "
            "if not ok then io.stderr:write(err .. '\\n'); vim.cmd('cquit 1') "
            "else vim.cmd('qa!') end end)"
        ),
    ]

    temp_root = Path("C:/dev/tmp")
    temp_root.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="nvim-file-messages-", dir=temp_root) as temp_dir:
        env["NVIM_TEST_TMP"] = Path(temp_dir).as_posix()
        try:
            result = run_nvim(nvim, command, cwd=config_dir, env=env, timeout=330)
        except subprocess.TimeoutExpired:
            print("  FAIL  startup - timed out")
            return 0, 1

    if result.returncode == 0:
        print("  OK    startup")
        return 1, 1

    print(f"  FAIL  startup - nvim exited with code {result.returncode}")
    output = "\n".join(
        part.strip() for part in (result.stdout, result.stderr) if part.strip()
    )
    if output:
        for line in output.splitlines():
            print(f"        {line}")
    return 0, 1


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    nvim = find_nvim()
    config_dir, data_dir = resolve_paths(nvim)
    tooling = load_tooling(nvim, config_dir)
    total_ok = 0
    total_all = 0

    print("=== lazy.nvim Plugins ===")
    plugins = load_lazy_lock(config_dir)
    ok, total = check_plugins(data_dir, plugins)
    total_ok += ok
    total_all += total
    print()

    print("=== Mason LSP Servers ===")
    ok, total = check_mason_lsp(data_dir, tooling["lsp_servers"])
    total_ok += ok
    total_all += total
    print()

    print("=== Formatters ===")
    ok, total = check_formatters(data_dir, tooling["formatters"])
    total_ok += ok
    total_all += total
    print()

    print("=== Neovim Startup ===")
    ok, total = check_nvim_startup(nvim, config_dir)
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
