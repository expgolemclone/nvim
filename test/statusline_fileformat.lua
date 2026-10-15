local original_format = vim.bo.fileformat
local original_filetype = vim.bo.filetype
vim.bo.filetype = "text"

for format, label in pairs({ unix = "LF", dos = "CRLF", mac = "CR" }) do
  vim.bo.fileformat = format
  local statusline = vim.api.nvim_eval_statusline(vim.o.statusline, { winid = 0 }).str
  assert(
    statusline:find(" | " .. label .. " | ", 1, true),
    ("Expected %s label for %s, got: %s"):format(label, format, statusline)
  )
  for _, os_name in ipairs({ "unix", "dos", "mac" }) do
    assert(not statusline:find(" | " .. os_name .. " | ", 1, true), statusline)
  end
  assert(vim.bo.fileformat == format, "Statusline must not change fileformat")
end

-- Statusline expressions must use the displayed window's buffer.
local original_win = vim.api.nvim_get_current_win()
vim.bo.fileformat = "dos"
vim.cmd("new")
local split_win = vim.api.nvim_get_current_win()
vim.bo.fileformat = "unix"
assert(vim.api.nvim_eval_statusline(vim.o.statusline, { winid = original_win }).str:find(" | CRLF | ", 1, true))
assert(vim.api.nvim_eval_statusline(vim.o.statusline, { winid = split_win }).str:find(" | LF | ", 1, true))
vim.api.nvim_win_close(split_win, true)

vim.bo.fileformat = original_format
vim.bo.filetype = original_filetype
print("Statusline line-ending check passed")
