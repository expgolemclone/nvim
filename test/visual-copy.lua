local function checked(fn)
  local ok, err = xpcall(fn, debug.traceback)
  if not ok then
    print(err)
    vim.cmd("cquit 1")
  end
end

checked(function()
  vim.o.swapfile = false
  vim.o.undofile = false

  -- Exercise the provider without replacing the user's system clipboard.
  local copied = { {}, "v" }
  local function copy(lines, regtype)
    copied = { lines, regtype }
  end
  local function paste()
    return copied
  end
  vim.g.clipboard = {
    name = "visual-copy-test",
    copy = { ["+"] = copy, ["*"] = copy },
    paste = { ["+"] = paste, ["*"] = paste },
    cache_enabled = 0,
  }
  vim.cmd("unlet! g:loaded_clipboard_provider")
  vim.cmd("runtime autoload/provider/clipboard.vim")
  assert(vim.o.clipboard == "unnamedplus", "Yanks must use the system clipboard")

  local lines = { "first line", "second line", "", "日本語 text" }
  local cases = {
    { keys = "Vjy", expected = { "first line", "second line" }, regtype = "V" },
    { keys = "Vj<C-c>", expected = { "first line", "second line" }, regtype = "V" },
    { keys = "jVk<C-c>", expected = { "first line", "second line" }, regtype = "V" },
    { keys = "vjl<C-c>", expected = { "first line", "se" }, regtype = "v" },
    { keys = "<C-v>j3l<C-c>", expected = { "firs", "seco" }, regtype = "\0224" },
    { keys = "VG<C-c>", expected = lines, regtype = "V" },
  }
  local filetypes = { "text", "markdown" }
  local function run_case(index)
    if index > #cases * #filetypes then
      for _, mode in ipairs({ "n", "i" }) do
        assert(vim.fn.maparg("<C-c>", mode) == "", "Ctrl+C must retain native behavior in " .. mode .. " mode")
      end
      print("Visual copying: " .. (#cases * #filetypes) .. " cases passed")
      vim.cmd("qa!")
      return
    end

    local case = cases[(index - 1) % #cases + 1]
    local filetype = filetypes[math.floor((index - 1) / #cases) + 1]
    local context = filetype .. " " .. case.keys
    vim.cmd("enew!")
    vim.bo.filetype = filetype
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    copied = { {}, "v" }
    local changedtick = vim.api.nvim_buf_get_changedtick(0)
    local keys = vim.api.nvim_replace_termcodes(case.keys, true, false, true)
    vim.api.nvim_feedkeys(keys, "xt", false)

    -- Unnamed clipboard yanks are flushed after the current command returns.
    vim.defer_fn(function()
      checked(function()
        assert(#copied[1] > 0, context .. ": did not copy to the clipboard provider")
        assert(vim.deep_equal(vim.fn.getreg("+", 1, true), case.expected), context .. ": wrong clipboard lines")
        assert(vim.fn.getregtype("+") == case.regtype, context .. ": wrong clipboard register type")
        assert(vim.fn.mode() == "n", context .. ": must leave Visual mode")
        assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), lines), context .. ": changed buffer")
        assert(vim.api.nvim_buf_get_changedtick(0) == changedtick, context .. ": copying must not add an edit")
        run_case(index + 1)
      end)
    end, 20)
  end
  run_case(1)
end)
