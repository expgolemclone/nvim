local config = require("lazy.core.config")
local endings_source = debug.getinfo(require("line_endings").label, "S").source:sub(2)
assert(
  vim.fs.normalize(endings_source)
    == vim.fs.normalize(vim.fs.joinpath(vim.env.NVIM_CONFIG_CHECKOUT, "lua", "line_endings.lua")),
  "Checkout modules must not resolve from another configuration: " .. endings_source
)
for _, name in ipairs({
  "Comment.nvim",
  "diffview.nvim",
  "friendly-snippets",
  "gitsigns.nvim",
  "indent-blankline.nvim",
  "lualine.nvim",
  "mason-lspconfig.nvim",
  "nabla.nvim",
  "neo-tree.nvim",
  "neogit",
  "noice.nvim",
  "nui.nvim",
  "todo-comments.nvim",
  "vim-sleuth",
}) do
  assert(not config.plugins[name], "Removed plugin still configured: " .. name)
end
assert(vim.fn.maparg(" e", "n") == "", "Removed tree map still exists")
assert(vim.fn.maparg(" gg", "n") == "", "Removed Git map still exists")
assert(vim.fn.maparg("gc", "n") ~= "", "Native commenting must be available")
assert(vim.fn.exists(":LspInstall") == 0 and vim.fn.exists(":LspUninstall") == 0, "Removed bridge commands remain")
for _, name in ipairs({ "telescope.nvim", "render-markdown.nvim", "markdown-preview.nvim", "mason-tool-installer.nvim" }) do
  assert(not config.plugins[name]._.loaded, "Unused plugin loaded at empty startup: " .. name)
end
for _, name in ipairs({ "conform.nvim", "nvim-lspconfig" }) do
  assert(config.plugins[name]._.loaded, "Required startup plugin was delayed: " .. name)
end
assert(vim.fn.maparg(" mp", "n") ~= "", "Markdown preview key is missing")
assert(vim.fn.exists(":MarkdownPreview") == 2, "Markdown preview command is missing")
local blink = require("blink.cmp.config")
assert(vim.deep_equal(blink.sources.default, { "lsp", "buffer" }), "Completion sources must omit snippets")
assert(blink.snippets.preset == "default", "LSP snippets must retain native expansion")

-- Load explicit provisioning without installing/updating anything.
require("lazy").load({ plugins = { "mason-tool-installer.nvim" } })
local opts = require("lazy.core.plugin").values(config.plugins["mason-tool-installer.nvim"], "opts", false)
assert(opts.run_on_start == false, "Tool installation must be explicit")
assert(opts.auto_update == false, "Tool updates must be explicit")
local packages = {}
for _, package in ipairs(opts.ensure_installed) do
  assert(not packages[package], "Duplicate provisioned package: " .. package)
  packages[package] = true
end
local tooling = require("tooling")
local expected = {}
for _, entries in ipairs({ tooling.lsp_servers, tooling.formatters }) do
  for _, entry in ipairs(entries) do
    expected[entry.package] = true
  end
end
assert(vim.deep_equal(packages, expected), "Provisioned packages must match tooling metadata exactly")
assert(vim.fn.exists(":MasonToolsInstallSync") == 2, "Explicit provisioning command is missing")
assert(not package.loaded["mason-lspconfig"], "Tool installer must not load the LSP provisioning bridge")

for _, formatter in ipairs(tooling.formatters) do
  local info = require("conform").get_formatter_info(formatter.name)
  assert(info.available, "Formatter unavailable: " .. formatter.name .. ": " .. tostring(info.available_msg))
  local resolved = vim.fn.exepath(info.command)
  assert(resolved ~= "", "Unresolved formatter command: " .. info.command)
  io.stdout:write(("Formatter %s resolves to %s\n"):format(formatter.name, resolved))
end

-- Check the upstream project dependency contract without executing the fixture.
local project = vim.fs.joinpath(assert(vim.env.NVIM_TEST_TMP), "project")
local bin = vim.fs.joinpath(project, "node_modules", ".bin")
vim.fn.mkdir(bin, "p")
local launcher = vim.fs.joinpath(bin, vim.fn.has("win32") == 1 and "oxfmt.cmd" or "oxfmt")
vim.fn.writefile({ "#!/bin/sh", "exit 0" }, launcher)
assert(vim.uv.fs_chmod(launcher, 493))
local original_buf = vim.api.nvim_get_current_buf()
local project_buf = vim.api.nvim_create_buf(false, false)
vim.bo[project_buf].swapfile = false
vim.bo[project_buf].undofile = false
vim.api.nvim_buf_set_name(project_buf, vim.fs.joinpath(project, "example.js"))
local info = require("conform").get_formatter_info("oxfmt", project_buf)
assert(info.available, "Upstream project-local oxfmt must remain available")
local resolved = vim.fs.normalize(vim.fn.exepath(info.command))
local expected_launcher = vim.fs.normalize(launcher)
if vim.fn.has("win32") == 1 then
  resolved = resolved:lower()
  expected_launcher = expected_launcher:lower()
end
assert(resolved == expected_launcher, "Project-local oxfmt was bypassed: " .. resolved)
vim.api.nvim_buf_delete(project_buf, { force = true })
assert(vim.api.nvim_get_current_buf() == original_buf)
print("Project-local oxfmt resolution check passed")

vim.api.nvim_feedkeys(" fb", "xt", false)
assert(config.plugins["telescope.nvim"]._.loaded, "Telescope key did not load its plugin")
assert(require("telescope").extensions.fzf, "Native fzf extension is missing")
require("telescope.actions").close(vim.api.nvim_get_current_buf())
print("Plugin lifecycle check passed")
