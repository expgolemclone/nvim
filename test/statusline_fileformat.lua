local lualine = require("lualine")
local original_format = vim.bo.fileformat
local original_filetype = vim.bo.filetype
vim.bo.filetype = "text"

for format, label in pairs({ unix = "LF", dos = "CRLF", mac = "CR" }) do
  vim.bo.fileformat = format
  lualine.refresh({ place = { "statusline" }, trigger = "test" })
  local statusline
  local rendered = vim.wait(2000, function()
    statusline = vim.api.nvim_eval_statusline(vim.wo.statusline, { winid = 0 }).str
    return statusline:find(" " .. label .. " |", 1, true) ~= nil
  end)
  assert(rendered, ("Expected %s label for %s, got: %s"):format(label, format, statusline))
  for _, os_name in ipairs({ "unix", "dos", "mac" }) do
    assert(
      not statusline:find(" " .. os_name .. " |", 1, true),
      "Statusline must label line endings, not OS names: " .. statusline
    )
  end
  assert(vim.bo.fileformat == format, "Statusline must not change fileformat")
end

vim.bo.fileformat = original_format
vim.bo.filetype = original_filetype
print("Statusline line-ending check passed")
