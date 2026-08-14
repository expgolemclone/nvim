return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "prettierd",
        "ruff",
        "shfmt",
        "stylua",
      },
      auto_update = false,
      run_on_start = true,
      integrations = {
        ["mason-lspconfig"] = false,
        ["mason-null-ls"] = false,
        ["mason-nvim-dap"] = false,
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = {
        timeout_ms = 2000,
        lsp_format = "never",
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
  },
}
