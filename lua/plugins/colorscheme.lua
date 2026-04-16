return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  opts = {
    flavour = "mocha",
    transparent_background = true,
    integrations = {
      cmp = true,
      gitsigns = true,
      neotree = true,
      treesitter = true,
      which_key = true,
      telescope = { enabled = true },
      indent_blankline = { enabled = true },
      native_lsp = { enabled = true },
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
