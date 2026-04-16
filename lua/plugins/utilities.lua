return {
  { "folke/which-key.nvim", opts = {} },
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
  { "numToStr/Comment.nvim", opts = {} },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
  { "nvim-tree/nvim-web-devicons", opts = {} },
  { "tpope/vim-sleuth" },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
}
