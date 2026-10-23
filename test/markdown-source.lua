local function main()
  vim.o.columns = 120
  vim.o.lines = 40
  vim.o.swapfile = false
  vim.o.undofile = false
  local source = {
    "# Markdown source",
    "",
    "- [x] A task",
    "> [!NOTE]",
    "[link](https://example.com)",
    "",
    "Inline $e^{i\\pi} + 1 = 0$ and $\\frac{1}{2}$.",
    "日本語 $A = \\pi r^2$ です.",
    "$$",
    "\\frac{a + b}{c} = \\sqrt{x}",
    "$$",
    "",
  }
  local probes = { { language = "markdown", row = 0, col = 2 } }
  for _, case in ipairs({
    { language = "javascript", text = "const answer = 42;" },
    { language = "python", text = "answer = 42" },
    { language = "bash", text = "count=42" },
  }) do
    source[#source + 1] = "```" .. case.language
    probes[#probes + 1] = { language = case.language, row = #source, col = 0 }
    source[#source + 1] = case.text
    source[#source + 1] = "```"
  end
  vim.cmd("enew!")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, source)
  vim.bo.filetype = "markdown"
  local parser = vim.treesitter.get_parser(buf, "markdown")
  parser:parse(true)
  for _, probe in ipairs(probes) do
    local found = false
    for _, capture in ipairs(vim.treesitter.get_captures_at_pos(buf, probe.row, probe.col)) do
      found = found or capture.lang == probe.language
    end
    assert(found, "Missing syntax highlighting: " .. probe.language)
  end

  local function assert_source(context)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd("normal! gg0")
    vim.cmd("redraw")
    assert(vim.wo.wrap, "Markdown must retain wrapping")
    assert(vim.wo.conceallevel == 0, "Markdown source must remain visible")
    assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), source), "Markdown source was modified")
    for row, line in ipairs(source) do
      local col = 1
      for _, char in ipairs(vim.fn.split(line, "\\zs")) do
        local pos = vim.fn.screenpos(0, row, col)
        assert(pos.row > 0, "Markdown source is offscreen: " .. context)
        assert(vim.fn.screenstring(pos.row, pos.col) == char, "Markdown source was concealed or replaced: " .. context)
        col = col + #char
      end
    end
  end

  assert_source("initial")
  source[7] = source[7] .. " + x^2"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, source)
  parser:parse(true)
  assert_source("edited math")
  vim.bo.filetype = "text"
  vim.bo.filetype = "markdown"
  assert_source("filetype reload")
  assert(vim.fn.exists(":RenderMarkdown") == 0, "Inline Markdown decoration must not return")
  assert(vim.fn.maparg(" mr", "n") == "", "Removed decoration key must not return")
  print("Markdown source and syntax highlighting checks passed")
end

local ok, err = xpcall(main, debug.traceback)
if not ok then
  print(err)
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
