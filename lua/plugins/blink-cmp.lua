local function termcodes(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function repeat_termcode(keys, count)
  if count <= 0 then
    return ""
  end

  return termcodes(keys):rep(count)
end

local function renumber_ordered_list(bufnr, start_row, indent, delimiter, start_number)
  local expected = start_number
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  for row = start_row, line_count do
    local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
    local item_indent, _, item_delimiter, rest = line:match("^(%s*)(%d+)([.)])(%s+.*)$")

    if item_indent ~= indent or item_delimiter ~= delimiter then
      return
    end

    local renumbered = ("%s%d%s%s"):format(indent, expected, delimiter, rest)
    if renumbered ~= line then
      vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, { renumbered })
    end

    expected = expected + 1
  end
end

local function renumber_ordered_list_soon(bufnr, start_row, indent, delimiter, start_number)
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      renumber_ordered_list(bufnr, start_row, indent, delimiter, start_number)
    end
  end, 0)
end

local function continue_ordered_list()
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local before = line:sub(1, col)
  local after = line:sub(col + 1)

  if not after:match("^%s*$") then
    return
  end

  local indent, number, delimiter, content = before:match("^(%s*)(%d+)([.)])%s+(.*)$")
  if not number then
    return
  end

  if content:match("^%s*$") then
    local delete_after = after == "" and "" or termcodes("<C-o>D")
    return delete_after .. repeat_termcode("<BS>", #before - #indent)
  end

  local delete_after = after == "" and "" or termcodes("<C-o>D")
  local trailing_spaces = before:match("(%s*)$")
  local delete_trailing_spaces = repeat_termcode("<BS>", #trailing_spaces)
  local next_number = tonumber(number) + 1

  renumber_ordered_list_soon(bufnr, row + 2, indent, delimiter, next_number + 1)

  return delete_after
    .. delete_trailing_spaces
    .. termcodes(("<C-g>u<CR>%d%s "):format(next_number, delimiter))
end

return {
  "saghen/blink.cmp",
  version = "*",
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  opts = {
    keymap = {
      preset = "default",
      ["<CR>"] = {
        function(cmp)
          if cmp.accept() then
            return true
          end

          return continue_ordered_list()
        end,
        "fallback",
      },
    },
    sources = {
      default = { "lsp", "snippets", "buffer" },
    },
    completion = {
      accept = { auto_brackets = { enabled = true } },
      documentation = { auto_show = true },
    },
  },
}
