-- Compare actual screen cells, not byte offsets or merely extmark presence.
return function(rm, render_and_wait)
  local cases = {
    "text $e^{i\\pi} + 1 = 0$ end",
    "日本語 $e^{i\\pi} + 1 = 0$ です",
    "円の面積は $A = \\pi r^2$ です. オイラーの等式 $e^{i\\pi} + 1 = 0$ も有名です.",
    "🙂 $e^{i\\pi} + 1 = 0$",
    "café $e^{i\\pi} + 1 = 0$",
    "👩‍💻 $e^{i\\pi} + 1 = 0$",
    "日本語\t $e^{i\\pi} + 1 = 0$",
    "**日本語** $e^{i\\pi} + 1 = 0$",
    "[日本語](https://example.com) $e^{i\\pi} + 1 = 0$",
    "$\\frac{1}{2}$ の後に $e^{i\\pi} + 1 = 0$",
  }
  local function assert_alignment(context)
    local baseline_row, e_col, exponent_col
    for row = 1, vim.o.lines - 2 do
      for col = 1, vim.o.columns - 4 do
        if vim.fn.screenstring(row, col) == "e" and vim.fn.screenstring(row, col + 4) == "+" then
          baseline_row, e_col = row, col
        end
      end
    end
    assert(baseline_row, "missing math baseline: " .. context)
    for col = 1, vim.o.columns - 1 do
      if
        vim.fn.screenstring(baseline_row - 1, col) == "i"
        and vim.fn.screenstring(baseline_row - 1, col + 1) == "π"
      then
        exponent_col = col
      end
    end
    assert(
      exponent_col == e_col + 1,
      ("%s: exponent column %s, expected %d"):format(context, tostring(exponent_col), e_col + 1)
    )
  end
  for index, source in ipairs(cases) do
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo[buf].filetype = "markdown"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "", source, "" })
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    vim.treesitter.start(buf, "markdown")
    local win = vim.api.nvim_get_current_win()
    render_and_wait(rm, buf, win, "math alignment " .. index)
    assert_alignment("case " .. index)

    vim.api.nvim_buf_set_lines(buf, 1, 2, false, { "追加 " .. source })
    render_and_wait(rm, buf, win, "edited math alignment " .. index)
    assert_alignment("edited case " .. index)

    -- Math must stay aligned even when the cursor enters the formula line.
    vim.api.nvim_win_set_cursor(win, { 2, 0 })
    vim.cmd("redraw")
    assert_alignment("cursor case " .. index)

    rm.buf_disable()
    local ns = require("markdown_math").ns
    assert(
      vim.wait(5000, function()
        return #vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {}) == 0
      end, 10),
      "disabling Markdown left math drawings behind"
    )
    rm.buf_enable()
    assert(
      vim.wait(5000, function()
        return #vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {}) > 0
      end, 10),
      "enabling Markdown did not restore math drawings"
    )
    vim.cmd("redraw")
    assert_alignment("reenabled case " .. index)
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  print(("  PASS  math_alignment       %d screen-cell cases, edits, cursor and toggles"):format(#cases))
end
