local function main()
  vim.o.swapfile = false
  vim.o.undofile = false
  local cases = {
    { name = "plain Markdown", input = { "plain" }, expected = { "plain", "next" } },
    { name = "dash list", input = { "- item" }, expected = { "- item", "- next" } },
    { name = "star list", input = { "* item" }, expected = { "* item", "* next" } },
    { name = "plus list", input = { "+ item" }, expected = { "+ item", "+ next" } },
    { name = "quote", input = { "> quote" }, expected = { "> quote", "> next" } },
    { name = "heading", input = { "### Heading" }, expected = { "### Heading", "next" } },
    { name = "task", input = { "- [x] done" }, expected = { "- [x] done", "- next" } },
    { name = "hard break", input = { "- item  " }, expected = { "- item  ", "- next" } },
    {
      name = "ordered items remain unchanged",
      input = { "1. one", "2. two" },
      expected = { "1. one", "next", "2. two" },
    },
    {
      name = "plain text",
      filetype = "text",
      input = { "plain" },
      expected = { "plain", "next" },
    },
    {
      name = "autopairs",
      filetype = "lua",
      input = { "{}" },
      col = 1,
      keys = "i<CR><Esc>",
      expected = { "{", "", "}" },
    },
  }
  for _, case in ipairs(cases) do
    vim.cmd("enew!")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, case.input)
    vim.bo.filetype = case.filetype or "markdown"
    vim.api.nvim_win_set_cursor(0, { 1, case.col or 0 })
    local keys = vim.api.nvim_replace_termcodes(case.keys or "A<CR>next<Esc>", true, false, true)
    vim.api.nvim_feedkeys(keys, "xt", false)
    local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(vim.deep_equal(actual, case.expected), case.name .. ": " .. vim.inspect(actual))
  end
  print(("Native Enter: %d cases passed"):format(#cases))
end

local ok, err = xpcall(main, debug.traceback)
if not ok then
  print(err)
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
