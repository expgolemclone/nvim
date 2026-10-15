local M = {}

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

  local number, delimiter = rest:match("^(%d+)([.)])%s+%[[ xX]%]%s+")
  if number then
    local next_number = tonumber(number) + 1
    return {
      text = ("%s%d%s [ ] "):format(base, next_number, delimiter),
      ordered = true,
      base = base,
      delimiter = delimiter,
      next_number = next_number,
    }
  end

  number, delimiter = rest:match("^(%d+)([.)])%s+")
  if number then
    local next_number = tonumber(number) + 1
    return {
      text = ("%s%d%s "):format(base, next_number, delimiter),
      ordered = true,
      base = base,
      delimiter = delimiter,
      next_number = next_number,
    }
  end

  local bullet = rest:match("^([-*+])%s+%[[ xX]%]%s+")
  if bullet then
    return { text = ("%s%s [ ] "):format(base, bullet) }
  end

  bullet = rest:match("^([-*+])%s+")
  if bullet then
    return { text = ("%s%s "):format(base, bullet) }
  end

  local heading = rest:match("^(#+)%s+")
  if heading and #heading <= 6 then
    return { text = ("%s%s "):format(base, heading) }
  end

  if base ~= "" then
    return { text = base:match("%s$") and base or base .. " " }
  end
end

local function insertion()
  if vim.bo.filetype ~= "markdown" then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  if not line:sub(col + 1):match("^%s*$") then
    return
  end

  -- Use Markdown block syntax, not injected code syntax or line heuristics.
  vim.treesitter.get_parser(buf, "markdown"):parse(true)
  local node =
    vim.treesitter.get_node({ bufnr = buf, pos = { row - 1, math.max(0, col - 1) }, ignore_injections = true })
  local list
  while node do
    if node:type() == "fenced_code_block" or node:type() == "indented_code_block" then
      return
    end
    if not list and node:type() == "list_item" then
      list = node:parent()
    end
    node = node:parent()
  end

  local marker = parse_marker(line:sub(1, col))
  if not marker then
    return
  end

  -- Preserve whitespace, including Markdown's two-space hard breaks.
  local replacement = { line, marker.text }
  local finish = row
  if marker.ordered and list then
    local siblings = {}
    local expected = marker.next_number + 1
    for child in list:iter_children() do
      local start = child:start()
      if child:type() == "list_item" and start >= row then
        local sibling = vim.api.nvim_buf_get_lines(buf, start, start + 1, false)[1]
        local base, rest = split_marker_base(sibling)
        local _, delimiter, tail = rest:match("^(%d+)([.)])(%s+.*)$")
        if base ~= marker.base or delimiter ~= marker.delimiter then
          break
        end
        siblings[start] = ("%s%d%s%s"):format(base, expected, delimiter, tail)
        finish = start + 1
        expected = expected + 1
      end
    end
    for index, text in ipairs(vim.api.nvim_buf_get_lines(buf, row, finish, false)) do
      replacement[#replacement + 1] = siblings[row + index - 1] or text
    end
  end
  return { buf = buf, row = row, finish = finish, lines = replacement, col = #marker.text }
end

function M.insert()
  local edit = assert(insertion(), "Markdown Enter context changed")
  -- One API edit keeps the inserted line and sibling numbering in one undo step.
  vim.api.nvim_buf_set_lines(edit.buf, edit.row - 1, edit.finish, false, edit.lines)
  vim.api.nvim_win_set_cursor(0, { edit.row + 1, edit.col })
end

function M.continue_marker()
  if insertion() then
    -- Expression mappings cannot edit text. Execute synchronously outside textlock.
    return vim.api.nvim_replace_termcodes("<C-g>u<Cmd>lua require('markdown_enter').insert()<CR>", true, false, true)
  end
end

return M
