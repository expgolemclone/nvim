return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "ファイル検索" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "テキスト検索" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "バッファ一覧" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "ヘルプ検索" },
    { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "最近のファイル" },
    { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "診断一覧" },
    { "gr", "<cmd>Telescope lsp_references<CR>", desc = "参照一覧" },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
    },
  },
  config = function()
    require("telescope").setup({})
    require("telescope").load_extension("fzf")
  end,
}
