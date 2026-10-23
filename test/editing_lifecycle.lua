local function main()
  local root = assert(vim.env.NVIM_TEST_TMP)
  vim.o.swapfile = false
  vim.o.undofile = false

  -- Native diagnostic keys preserve count semantics in both directions.
  vim.cmd.enew()
  local diagnostic_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(diagnostic_buf, 0, -1, false, {
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
  })
  local ns = vim.api.nvim_create_namespace("editing-diagnostics")
  vim.diagnostic.set(ns, diagnostic_buf, {
    { lnum = 2, col = 0, message = "first", severity = vim.diagnostic.severity.WARN },
    { lnum = 4, col = 0, message = "second", severity = vim.diagnostic.severity.WARN },
    { lnum = 6, col = 0, message = "third", severity = vim.diagnostic.severity.WARN },
  })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.api.nvim_feedkeys("2]d", "xt", false)
  assert(vim.api.nvim_win_get_cursor(0)[1] == 5, "2]d must visit the second diagnostic")
  vim.api.nvim_win_set_cursor(0, { 9, 0 })
  vim.api.nvim_feedkeys("2[d", "xt", false)
  assert(vim.api.nvim_win_get_cursor(0)[1] == 5, "2[d must visit the second diagnostic")
  vim.diagnostic.reset(ns, diagnostic_buf)

  -- Native commenting replaces Comment.nvim.
  vim.cmd.enew({ bang = true })
  vim.bo.filetype = "lua"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local answer = 42" })
  vim.api.nvim_feedkeys("gcc", "xt", false)
  assert(vim.api.nvim_get_current_line():match("^%-%-"), "Native gcc did not comment")
  vim.api.nvim_feedkeys("gcc", "xt", false)
  assert(vim.api.nvim_get_current_line() == "local answer = 42", "Native gcc did not uncomment")

  -- All configured filetypes retain syntax and Tree-sitter indentation.
  for _, filetype in ipairs({
    "bash",
    "css",
    "dockerfile",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "lua",
    "markdown",
    "python",
    "sh",
    "typescript",
    "typescriptreact",
    "yaml",
  }) do
    vim.cmd.enew({ bang = true })
    vim.bo.filetype = filetype
    assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "Missing highlighter: " .. filetype)
    assert(vim.bo.indentexpr == "v:lua.require'nvim-treesitter'.indentexpr()", "Missing indentexpr: " .. filetype)
  end

  -- Preserve real fileformat bytes and detection without Noice.
  vim.opt.fileformats = { "unix", "dos", "mac" }
  for format, separator in pairs({ unix = "\n", dos = "\r\n", mac = "\r" }) do
    local path = vim.fs.joinpath(root, format .. ".txt")
    vim.cmd.enew({ bang = true })
    vim.bo.fileformat = format
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hello", "world" })
    vim.cmd.write(vim.fn.fnameescape(path))
    assert(not vim.bo.modified and vim.bo.fileformat == format)
    local file = assert(io.open(path, "rb"))
    assert(file:read("*a") == "hello" .. separator .. "world" .. separator, "Changed bytes: " .. format)
    file:close()
    vim.cmd.bdelete()
    vim.cmd.edit(vim.fn.fnameescape(path))
    assert(vim.bo.fileformat == format, "Wrong detected fileformat: " .. format)
  end

  -- Exercise native LSP activation and an actual completion request.
  local lua_path = vim.fs.joinpath(root, "completion.lua")
  vim.fn.writefile({ "local value=1", "math." }, lua_path)
  vim.cmd.edit(vim.fn.fnameescape(lua_path))
  local buf = vim.api.nvim_get_current_buf()
  assert(
    vim.wait(30000, function()
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf, name = "lua_ls" })) do
        if client.initialized then
          return true
        end
      end
      return false
    end, 20),
    "lua_ls did not initialize"
  )
  local clients = vim.lsp.get_clients({ bufnr = buf, name = "lua_ls" })
  -- initialized precedes didOpen/workspace readiness; wait for useful completions.
  local items
  assert(
    vim.wait(30000, function()
      local responses = vim.lsp.buf_request_sync(buf, "textDocument/completion", {
        textDocument = { uri = vim.uri_from_bufnr(buf) },
        position = { line = 1, character = 5 },
        context = { triggerKind = 1 },
      }, 2000)
      local response = responses and responses[clients[1].id]
      if not response then
        return false
      end
      assert(not response.err, vim.inspect(response.err))
      if not response.result then
        return false
      end
      items = response.result.items or response.result
      return #items > 0
    end, 100),
    "LSP completion never became ready"
  )
  local found = false
  for _, item in ipairs(items) do
    if item.label:match("sqrt") then
      found = true
    end
  end
  assert(found, "Expected math.sqrt completion")

  -- Saving still synchronously formats supported files.
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local value=1", "print(value)" })
  vim.cmd.write()
  assert(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "local value = 1", "First Lua save was not formatted")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local value=2" })
  vim.api.nvim_feedkeys(" cf", "xt", false)
  assert(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "local value = 2", "Manual formatting key did not format")
  vim.cmd.write()
  local md_path = vim.fs.joinpath(root, "format.md")
  vim.fn.writefile({ "#   Heading", "", "-   item" }, md_path)
  vim.cmd.edit(vim.fn.fnameescape(md_path))
  local md_buf = vim.api.nvim_get_current_buf()
  assert(
    vim.wait(15000, function()
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = md_buf, name = "marksman" })) do
        if client.initialized then
          return true
        end
      end
      return false
    end, 20),
    "marksman did not initialize"
  )
  vim.cmd.write()
  assert(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "# Heading", "Markdown save was not formatted")
  print("Editing lifecycle check passed")
end

local ok, err = xpcall(main, debug.traceback)
if not ok then
  print(err)
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
