local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
-- A checkout loaded with -u must not import modules from another checkout.
vim.opt.rtp:remove(vim.fn.stdpath("config"))
vim.opt.rtp:remove(vim.fn.stdpath("config") .. "/after")
vim.opt.rtp:prepend(config_dir)

-- neovim.nixから移植したopts
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.updatetime = 250
vim.opt.undofile = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.background = "dark"
vim.opt.statusline = "%f %m%r%=%{&fileencoding} | %{v:lua.require'line_endings'.label()} | %y %l:%c %p%%"

if vim.fn.has("win32") == 1 then
  vim.opt.shell = "pwsh"
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -NonInteractive -Command "
    .. "[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();"
    .. "$PSStyle.OutputRendering='PlainText';"
  vim.opt.shellpipe = "> %s 2>&1"
  vim.opt.shellredir = "> %s 2>&1"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
  vim.opt.shelltemp = false
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("Failed to clone lazy.nvim:\n" .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  lockfile = vim.fs.joinpath(config_dir, "lazy-lock.json"),
  performance = { rtp = { reset = false } },
  spec = { { import = "plugins" } },
  ui = {
    icons = {
      cmd = "$ ",
      config = "* ",
      event = "@ ",
      favorite = "* ",
      ft = "file ",
      init = "init ",
      import = "import ",
      keys = "key ",
      lazy = "lazy ",
      plugin = "plugin ",
      runtime = "runtime ",
      require = "require ",
      source = "src ",
      start = "start ",
    },
  },
})

-- バッファ
vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "バッファを閉じる" })

-- ウィンドウ分割
vim.keymap.set("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "縦分割" })
vim.keymap.set("n", "<leader>sh", "<cmd>split<CR>", { desc = "横分割" })

-- ESC でハイライト解除
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "ハイライト解除" })
