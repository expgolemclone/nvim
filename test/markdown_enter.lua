local function termcodes(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local cases = {
  {
    name = "plain markdown line",
    input = { "plain" },
    expected = { "plain", "" },
  },
  {
    name = "plain non-markdown line",
    filetype = "text",
    input = { "plain" },
    expected = { "plain", "" },
  },
  {
    name = "dash list",
    input = { "- " },
    expected = { "- ", "- " },
  },
  {
    name = "star list",
    input = { "* " },
    expected = { "* ", "* " },
  },
  {
    name = "nested plus list",
    input = { "  + " },
    expected = { "  + ", "  + " },
  },
  {
    name = "task list",
    input = { "- [x] " },
    expected = { "- [x] ", "- [ ] " },
  },
  {
    name = "heading",
    input = { "### " },
    expected = { "### ", "### " },
  },
  {
    name = "blockquote",
    input = { "> " },
    expected = { "> ", "> " },
  },
  {
    name = "ordered dot",
    input = { "3. " },
    expected = { "3. ", "4. " },
  },
  {
    name = "ordered paren",
    input = { "3) " },
    expected = { "3) ", "4) " },
  },
  {
    name = "renumber following ordered items",
    input = { "1. one", "2. two", "3. three" },
    expected = { "1. one", "2. ", "3. two", "4. three" },
  },
  {
    name = "renumber after empty ordered item",
    input = { "1. one", "2. two", "3. ", "3. hey" },
    row = 3,
    expected = { "1. one", "2. two", "3. ", "4. ", "5. hey" },
  },
}

local function assert_lines(case)
  local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  for i, expected_line in ipairs(case.expected) do
    assert(
      actual[i] == expected_line,
      ("%s line %d: expected %q, got %q"):format(case.name, i, expected_line, actual[i])
    )
  end

  assert(
    #actual == #case.expected,
    ("%s: expected %d lines, got %d"):format(case.name, #case.expected, #actual)
  )
end

local function run_case(index)
  local case = cases[index]
  if not case then
    print(("markdown enter: %d cases passed"):format(#cases))
    vim.cmd("qa!")
    return
  end

  vim.cmd("enew!")
  vim.bo.filetype = case.filetype or "markdown"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, case.input)
  vim.api.nvim_win_set_cursor(0, { case.row or 1, 0 })
  vim.api.nvim_input("A")

  vim.defer_fn(function()
    vim.api.nvim_input(termcodes("<CR><Esc>"))

    vim.defer_fn(function()
      local ok, message = pcall(assert_lines, case)
      if not ok then
        print(message)
        print(vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false)))
        vim.cmd("cquit")
        return
      end

      run_case(index + 1)
    end, 150)
  end, 50)
end

run_case(1)
