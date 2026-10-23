local preview_url
local original_open = vim.ui.open
-- Capture browser navigation without opening a GUI during the test.
vim.ui.open = function(url)
  preview_url = url
end

local function main()
  vim.o.swapfile = false
  vim.o.undofile = false
  local root = assert(vim.env.NVIM_TEST_TMP)
  local path = vim.fs.joinpath(root, "preview file.md")
  vim.fn.writefile({ "# Preview verification", "", "日本語 $x^2$" }, path)
  vim.cmd.edit(vim.fn.fnameescape(path))

  local socket = assert(vim.uv.new_tcp())
  assert(socket:bind("127.0.0.1", 0))
  local port = socket:getsockname().port
  socket:close()
  require("livepreview.config").set({ port = port })

  vim.api.nvim_feedkeys(" mp", "xt", false)
  assert(type(preview_url) == "string", "Markdown preview did not publish a URL")
  local response = vim
    .system({
      "curl",
      "--fail",
      "--silent",
      "--show-error",
      "--max-time",
      "10",
      "--header",
      "Accept: text/html",
      preview_url,
    }, { text = true })
    :wait(15000)
  assert(response.code == 0, response.stderr)
  assert(response.stdout:lower():find("<html", 1, true), "Markdown preview did not serve HTML")
  assert(response.stdout:find("Preview verification", 1, true), "Preview HTML did not contain the current file")
  print("Markdown preview service and key checks passed")
end

local ok, err = xpcall(main, debug.traceback)
vim.ui.open = original_open
local stopped, stop_err = pcall(vim.cmd, "LivePreview close")
if not ok or not stopped then
  print(err or stop_err)
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
