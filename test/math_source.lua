return function(rm, render_and_wait, disable_and_wait, enable_and_wait)
  local cases = {
    { "Inline $e^{i\\pi} + 1 = 0$ and $\\frac{1}{2}$." },
    { "日本語 $A = \\pi r^2$ です." },
    { "$$", "\\frac{a + b}{c} = \\sqrt{x}", "$$" },
  }
  for index, source in ipairs(cases) do
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, source)
    vim.bo[buf].filetype = "markdown"
    vim.treesitter.start(buf, "markdown")
    local win = vim.api.nvim_get_current_win()

    local function assert_source(context)
      vim.api.nvim_win_set_cursor(win, { 1, 0 })
      vim.cmd("normal! gg")
      vim.cmd("redraw")
      assert(vim.wo[win].wrap, "Math source must preserve wrapping")
      assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), source), "Math source was modified")
      for row, line in ipairs(source) do
        -- Check the actual screen, including dollar delimiters, commands and braces.
        local col = 1
        for char in line:gmatch("[\1-\127\194-\244][\128-\191]*") do
          local pos = vim.fn.screenpos(win, row, col)
          assert(pos.row > 0, "Math source is offscreen: " .. context)
          assert(vim.fn.screenstring(pos.row, pos.col) == char, "Math source was concealed or replaced: " .. context)
          col = col + #char
        end
      end
      for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
        local details = mark[4]
        assert(details.virt_lines == nil and details.virt_text == nil, "Math must not create virtual drawings")
        assert(details.conceal == nil and details.conceal_lines == nil, "Math source must not be concealed")
      end
    end

    render_and_wait(rm, buf, win, "raw math " .. index)
    assert_source("initial case " .. index)
    local edited_row = #source == 3 and 2 or 1
    source[edited_row] = source[edited_row] .. " + x^2"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, source)
    render_and_wait(rm, buf, win, "edited raw math " .. index)
    assert_source("edited case " .. index)
    disable_and_wait(rm, buf)
    assert_source("disabled case " .. index)
    enable_and_wait(rm, buf)
    assert_source("reenabled case " .. index)
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  assert(not package.loaded["markdown_math"], "Removed math renderer was loaded")
  assert(not package.loaded["nabla"], "Removed Nabla dependency was loaded")
  print(("  PASS  math_source          %d raw-screen cases, edits and toggles"):format(#cases))
end
