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

require("lazy").setup("plugins")

-- Telescope
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "ファイル検索" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "テキスト検索" })
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "バッファ一覧" })
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "ヘルプ検索" })
vim.keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", { desc = "最近のファイル" })
vim.keymap.set("n", "<leader>fd", "<cmd>Telescope diagnostics<CR>", { desc = "診断一覧" })

-- Neo-tree
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "ファイルツリー" })

-- LSP
vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { desc = "定義へジャンプ" })
vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { desc = "宣言へジャンプ" })
vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", { desc = "実装へジャンプ" })
vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", { desc = "参照一覧" })
vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", { desc = "ホバー情報" })
vim.keymap.set("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", { desc = "コードアクション" })
vim.keymap.set("n", "<leader>cr", "<cmd>lua vim.lsp.buf.rename()<CR>", { desc = "リネーム" })
vim.keymap.set("n", "<leader>cf", "<cmd>lua require('conform').format()<CR>", { desc = "フォーマット" })

-- 診断
vim.keymap.set("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { desc = "前の診断" })
vim.keymap.set("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", { desc = "次の診断" })

-- Git
vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<CR>", { desc = "Neogit を開く" })

-- マークダウン
vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreview<CR>", { desc = "MD プレビュー" })
vim.keymap.set("n", "<leader>mr", "<cmd>RenderMarkdown toggle<CR>", { desc = "MD 装飾トグル" })

-- バッファ
vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "バッファを閉じる" })

-- ウィンドウ分割
vim.keymap.set("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "縦分割" })
vim.keymap.set("n", "<leader>sh", "<cmd>split<CR>", { desc = "横分割" })

-- ESC でハイライト解除
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "ハイライト解除" })
