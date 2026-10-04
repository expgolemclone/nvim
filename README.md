# Neovim configuration

The statusline and Noice file messages label line endings as `LF`, `CRLF`, and
`CR`. This only changes display, not file contents. Message history uses the same
labels.

Markdown math uses Nabla drawings with display-cell positioning, so Japanese
text and earlier formulas do not shift exponents or fractions. Rendering checks
use `sample.md` and screen-cell alignment regressions.

The checkout is the canonical configuration. On Windows, expose it at
`%LOCALAPPDATA%\nvim` with the idempotent setup script:

```powershell
pwsh -NoProfile -File .\tools\setup-nvim.ps1 -ValidateOnly
pwsh -NoProfile -File .\tools\setup-nvim.ps1
```

The script accepts an absent target, the expected junction, or an empty real
directory. It refuses to replace a non-empty directory or a junction to a
different location.

After setup, install/update the locked plugins and Mason tools, then run both
acceptance checks:

```powershell
nvim --headless "+Lazy! restore" +qa
nvim --headless "+MasonToolsInstallSync" +qa
python .\test\check_setup.py
python .\test\check_rendering.py
```
