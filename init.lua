-- Minimal config: enable truecolor + syntax highlighting + a builtin colorscheme.
vim.opt.termguicolors = true
vim.cmd('syntax enable')
vim.opt.number = true
-- Always use the OS clipboard for yank/paste (requires a working clipboard provider).
vim.opt.clipboard = "unnamedplus"
vim.opt.background = 'dark'

pcall(vim.cmd.colorscheme, 'habamax')

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")

-- LSP: marksman for Markdown (Neovim 0.11+ native API)
vim.lsp.config("marksman", {
  cmd = { vim.fs.joinpath(os.getenv("LOCALAPPDATA") or "", "Microsoft/WinGet/Packages/Artempyanykh.Marksman_Microsoft.Winget.Source_8wekyb3d8bbwe/marksman.exe"), "server" },
  filetypes = { "markdown", "markdown.mdx" },
  root_markers = { ".marksman.toml", ".git" },
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})
vim.lsp.enable("marksman")
