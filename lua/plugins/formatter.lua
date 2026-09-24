local tooling = require("tooling")

local formatter_packages = {}
for _, formatter in ipairs(tooling.formatters) do
  formatter_packages[#formatter_packages + 1] = formatter.package
end

return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = formatter_packages,
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
      default_format_opts = {
        timeout_ms = 10000,
      },
      format_on_save = {
        lsp_format = "never",
      },
      formatters_by_ft = tooling.formatters_by_ft,
    },
  },
}
