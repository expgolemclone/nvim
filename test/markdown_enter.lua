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
    undo = true,
  },
  {
    name = "renumber after empty ordered item",
    input = { "1. one", "2. two", "3. ", "3. hey" },
    row = 3,
    expected = { "1. one", "2. two", "3. ", "4. ", "5. hey" },
  },
}

for _, count in ipairs({ 1, 2, 3, 4, 8 }) do
  cases[#cases + 1] = {
    name = "preserve trailing spaces " .. count,
    input = { "- item" .. string.rep(" ", count) },
    expected = { "- item" .. string.rep(" ", count), "- " },
    undo = true,
  }
end
for _, fence in ipairs({ "```text", "~~~text", "> ```text" }) do
  local quote = fence:sub(1, 1) == ">" and "> " or ""
  local close = quote .. fence:gsub("^> ", ""):sub(1, 3)
  cases[#cases + 1] = {
    name = "no list edits in " .. fence,
    input = { fence, quote .. "1. value", quote .. "2. next", close },
    row = 2,
    expected = { fence, quote .. "1. value", "", quote .. "2. next", close },
  }
end
vim.list_extend(cases, {
  {
    name = "indented code",
    input = { "    1. value", "    2. next" },
    expected = { "    1. value", "", "    2. next" },
  },
  {
    name = "nested content and multiline sibling",
    input = { "1. one", "   - child", "2. two", "   continuation", "3. three", "", "paragraph", "1. separate" },
    expected = {
      "1. one",
      "2. ",
      "   - child",
      "3. two",
      "   continuation",
      "4. three",
      "",
      "paragraph",
      "1. separate",
    },
    undo = true,
  },
  {
    name = "quoted ordered tasks",
    input = { "> 1. [x] one", ">    - child", "> 2. [ ] two" },
    expected = { "> 1. [x] one", "> 2. [ ] ", ">    - child", "> 3. [ ] two" },
    undo = true,
  },
  {
    name = "autopairs Enter",
    filetype = "lua",
    input = { "{}" },
    col = 1,
    expected = { "{", "", "}" },
  },
  {
    name = "typing after marker",
    input = { "- item" },
    keys = "<CR>next<Esc>",
    expected = { "- item", "- next" },
  },
  {
    name = "repeated ordered Enter",
    input = { "1. one", "2. two" },
    keys = "<CR>new<CR><Esc>",
    expected = { "1. one", "2. new", "3. ", "4. two" },
  },
})

local function assert_lines(case)
  local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  for i, expected_line in ipairs(case.expected) do
    assert(
      actual[i] == expected_line,
      ("%s line %d: expected %q, got %q"):format(case.name, i, expected_line, actual[i])
    )
  end

  assert(#actual == #case.expected, ("%s: expected %d lines, got %d"):format(case.name, #case.expected, #actual))
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
  vim.bo.undolevels = -1
  vim.api.nvim_buf_set_lines(0, 0, -1, false, case.input)
  vim.bo.undolevels = 1000
  vim.api.nvim_win_set_cursor(0, { case.row or 1, case.col or 0 })
  vim.api.nvim_input(case.col and "i" or "A")

  vim.defer_fn(function()
    vim.api.nvim_input(termcodes(case.keys or "<CR><Esc>"))

    vim.defer_fn(function()
      local ok, message = pcall(function()
        assert_lines(case)
        if case.undo then
          vim.cmd("normal! u")
          assert_lines({ name = case.name .. " undo", expected = case.input })
          vim.api.nvim_feedkeys(termcodes("<C-r>"), "xt", false)
          assert_lines(case)
        end
      end)
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
