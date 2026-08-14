local M = {}

local function termcodes(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function repeat_termcode(keys, count)
  if count <= 0 then
    return ""
  end

  return termcodes(keys):rep(count)
end

local function split_marker_base(text)
  local indent, rest = text:match("^(%s*)(.*)$")
  local quote_prefix = ""

  while true do
    local quote = rest:match("^(>%s*)")
    if not quote then
      break
    end

    quote_prefix = quote_prefix .. quote
    rest = rest:sub(#quote + 1)
  end

  return indent .. quote_prefix, rest
end

local function parse_marker(before)
  local base, rest = split_marker_base(before)

  local number, delimiter, content = rest:match("^(%d+)([.)])%s+%[[ xX]%]%s+(.*)$")
  if number then
    local next_number = tonumber(number) + 1
    return {
      text = ("%s%d%s [ ] "):format(base, next_number, delimiter),
      empty = content:match("^%s*$") ~= nil,
      ordered = true,
      base = base,
      delimiter = delimiter,
      next_number = next_number,
    }
  end

  number, delimiter, content = rest:match("^(%d+)([.)])%s+(.*)$")
  if number then
    local next_number = tonumber(number) + 1
    return {
      text = ("%s%d%s "):format(base, next_number, delimiter),
      empty = content:match("^%s*$") ~= nil,
      ordered = true,
      base = base,
      delimiter = delimiter,
      next_number = next_number,
    }
  end

  local bullet
  bullet, content = rest:match("^([-*+])%s+%[[ xX]%]%s+(.*)$")
  if bullet then
    return { text = ("%s%s [ ] "):format(base, bullet), empty = content:match("^%s*$") ~= nil }
  end

  bullet, content = rest:match("^([-*+])%s+(.*)$")
  if bullet then
    return { text = ("%s%s "):format(base, bullet), empty = content:match("^%s*$") ~= nil }
  end

  local heading
  heading, content = rest:match("^(#+)%s+(.*)$")
  if heading and #heading <= 6 then
    return { text = ("%s%s "):format(base, heading), empty = content:match("^%s*$") ~= nil }
  end

  if base ~= "" then
    return { text = base:match("%s$") and base or base .. " ", empty = rest:match("^%s*$") ~= nil }
  end
end

local function renumber_ordered_list(bufnr, start_row, base, delimiter, start_number)
  local expected = start_number
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  for row = start_row, line_count do
    local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
    local item_base, rest = split_marker_base(line)
    local _, item_delimiter, tail = rest:match("^(%d+)([.)])(%s+.*)$")

    if item_base ~= base or item_delimiter ~= delimiter then
      return
    end

    local renumbered = ("%s%d%s%s"):format(base, expected, delimiter, tail)
    if renumbered ~= line then
      vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, { renumbered })
    end

    expected = expected + 1
  end
end

local function renumber_ordered_list_soon(bufnr, start_row, base, delimiter, start_number)
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      renumber_ordered_list(bufnr, start_row, base, delimiter, start_number)
    end
  end, 0)
end

function M.continue_marker()
  if vim.bo.filetype ~= "markdown" then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local before = line:sub(1, col)
  local after = line:sub(col + 1)

  if not after:match("^%s*$") then
    return
  end

  local marker = parse_marker(before)
  if not marker then
    return
  end

  if marker.ordered then
    renumber_ordered_list_soon(bufnr, row + 2, marker.base, marker.delimiter, marker.next_number + 1)
  end

  local delete_after = after == "" and "" or termcodes("<C-o>D")
  local trailing_spaces = before:match("(%s*)$")
  local delete_trailing_spaces = marker.empty and "" or repeat_termcode("<BS>", #trailing_spaces)

  return delete_after .. delete_trailing_spaces .. termcodes("<C-g>u<CR><C-o>0<C-o>D") .. marker.text
end

return M
