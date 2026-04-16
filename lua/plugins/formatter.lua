return {
  "stevearc/conform.nvim",
  opts = {
    format_on_save = {
      timeout_ms = 2000,
      lsp_format = "fallback",
    },
    formatters_by_ft = {
      python = { "ruff_format" },
      javascript = { "prettierd" },
      typescript = { "prettierd" },
      javascriptreact = { "prettierd" },
      typescriptreact = { "prettierd" },
      html = { "prettierd" },
      css = { "prettierd" },
      json = { "prettierd" },
      yaml = { "prettierd" },
      markdown = { "prettierd" },
      lua = { "stylua" },
      sh = { "shfmt" },
      bash = { "shfmt" },
    },
  },
}
