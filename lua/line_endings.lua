local M = {}
local labels = { unix = "LF", dos = "CRLF", mac = "CR" }

function M.label()
  return labels[vim.bo.fileformat]
end

return M
