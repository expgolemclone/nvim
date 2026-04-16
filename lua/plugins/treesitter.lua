return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.config").setup({
      highlight = { enable = true },
      indent = { enable = true },
    })
  end,
}
