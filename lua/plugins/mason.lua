local tooling = require("tooling")

local packages = {}
for _, entries in ipairs({ tooling.lsp_servers, tooling.formatters }) do
  for _, entry in ipairs(entries) do
    if not vim.list_contains(packages, entry.package) then
      packages[#packages + 1] = entry.package
    end
  end
end

return {
  {
    "mason-org/mason.nvim",
    opts = {},
    build = ":MasonUpdate",
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    cmd = {
      "MasonToolsInstall",
      "MasonToolsInstallSync",
      "MasonToolsUpdate",
      "MasonToolsUpdateSync",
      "MasonToolsClean",
    },
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = packages,
      auto_update = false,
      run_on_start = false,
      integrations = {
        ["mason-lspconfig"] = false,
        ["mason-null-ls"] = false,
        ["mason-nvim-dap"] = false,
      },
    },
  },
}
