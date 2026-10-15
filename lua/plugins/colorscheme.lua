return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  opts = {
    flavour = "mocha",
    transparent_background = true,
    integrations = {
      blink_cmp = { style = "bordered" },
      treesitter = true,
      which_key = true,
      telescope = { enabled = true },
      native_lsp = { enabled = true },
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
