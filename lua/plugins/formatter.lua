return {
  "stevearc/conform.nvim",
  lazy = false,
  keys = {
    { "<leader>cf", "<cmd>lua require('conform').format()<CR>", desc = "フォーマット" },
  },
  opts = {
    default_format_opts = {
      timeout_ms = 10000,
    },
    format_on_save = {
      lsp_format = "never",
    },
    formatters_by_ft = require("tooling").formatters_by_ft,
  },
}
