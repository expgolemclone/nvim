return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
    },
  },
  { "NeogitOrg/neogit", dependencies = { "nvim-lua/plenary.nvim" }, opts = {} },
  { "sindrets/diffview.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
}
