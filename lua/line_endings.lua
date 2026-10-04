local M = {}

M.labels = { unix = "LF", dos = "CRLF", mac = "CR" }

-- Only replace native file-info flags, never bracketed text in the filename.
function M.file_message(text)
  local filename, flags, counts = text:match('^(".*"%s+)(.-)(%d+[%a ]+, %d+[%a ]+.*)$')
  if not filename then
    return text
  end
  flags = flags:gsub("%[([a-z]+)%]", function(format)
    if M.labels[format] then
      return "[" .. M.labels[format] .. "]"
    end
    return "[" .. format .. "]"
  end)
  return filename .. flags .. counts
end

return M
