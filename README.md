# Neovim configuration

The checkout is the canonical configuration. On Windows, expose it at
`%LOCALAPPDATA%\nvim` with the idempotent setup script:

```powershell
pwsh -NoProfile -File .\tools\setup-nvim.ps1 -ValidateOnly
pwsh -NoProfile -File .\tools\setup-nvim.ps1
```

The script accepts an absent target, the expected junction, or an empty real
directory. It refuses to replace a non-empty directory or a junction to a
different location.

After setup, install/update the locked plugins and Mason tools, then build parsers
and run the acceptance checks. Use Developer PowerShell for Visual Studio on
Windows so the parser build can find the C compiler, and install `tree-sitter-cli`
before building parsers:

```powershell
nvim --headless "+Lazy! restore" +qa
nvim --headless "+MasonToolsInstallSync" +qa
nvim --headless "+Lazy! build nvim-treesitter" +qa
python .\test\check_setup.py
python .\test\check_rendering.py
python .\test\check_editing.py
```
