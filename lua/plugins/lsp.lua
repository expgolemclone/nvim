return {
  {
    "williamboman/mason.nvim",
    opts = {},
    build = ":MasonUpdate",
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "pyright",
        "ruff",
        "ts_ls",
        "lua_ls",
        "html",
        "cssls",
        "jsonls",
        "yamlls",
        "bashls",
        "dockerls",
        "marksman",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      local servers = {
        "pyright",
        "ruff",
        "ts_ls",
        "lua_ls",
        "html",
        "cssls",
        "jsonls",
        "yamlls",
        "bashls",
        "dockerls",
        "marksman",
      }

      for _, server in ipairs(servers) do
        vim.lsp.config(server, {
          capabilities = capabilities,
        })
        vim.lsp.enable(server)
      end
    end,
  },
}
