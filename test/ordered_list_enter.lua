local function termcodes(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function assert_lines(expected)
  local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  for i, expected_line in ipairs(expected) do
    assert(actual[i] == expected_line, ("line %d: expected %q, got %q"):format(i, expected_line, actual[i]))
  end

  assert(#actual == #expected, ("expected %d lines, got %d"):format(#expected, #actual))
end

local function finish(ok, message)
  if ok then
    print(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
    vim.cmd("qa!")
  else
    print(message)
    vim.cmd("cquit")
  end
end

vim.cmd("enew")
vim.bo.filetype = "markdown"
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "1. one",
  "2. two",
  "3. three",
})
vim.api.nvim_win_set_cursor(0, { 1, 5 })

vim.api.nvim_input("a")
vim.defer_fn(function()
  vim.api.nvim_input(termcodes("<CR><Esc>"))

  vim.defer_fn(function()
    local ok, message = pcall(function()
      assert_lines({
        "1. one",
        "2. ",
        "3. two",
        "4. three",
      })
    end)

    finish(ok, message)
  end, 100)
end, 100)
