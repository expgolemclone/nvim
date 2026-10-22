if vim.fn.has("win32") == 0 then
  return
end

assert(vim.o.shell == "mise.exe", "Windows shell must delegate runtime selection to mise")
assert(vim.o.shellcmdflag:find("exec -- pwsh ", 1, true) == 1)
local selected = vim.system({ "mise.exe", "which", "pwsh" }, { text = true }):wait()
assert(selected.code == 0, selected.stderr)
local actual = vim.fn.system("[Console]::Write((Get-Process -Id $PID).Path)")
assert(vim.v.shell_error == 0, actual)
local function normalize(value)
  return vim.fs.normalize(vim.trim(value)):lower()
end
assert(normalize(actual) == normalize(selected.stdout), "Shell launched a different PowerShell")
local output = vim.fn.system("[Console]::Write('業務 & quote''s text'); exit 9")
assert(output == "業務 & quote's text", output)
assert(vim.v.shell_error == 9, "Shell must preserve PowerShell failures")
