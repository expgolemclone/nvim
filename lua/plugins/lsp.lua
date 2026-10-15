local tooling = require("tooling")

return {
  "neovim/nvim-lspconfig",
  lazy = false,
  dependencies = {
    "mason-org/mason.nvim",
    "saghen/blink.cmp",
  },
  keys = {
    { "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "定義へジャンプ" },
    { "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", desc = "宣言へジャンプ" },
    { "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", desc = "実装へジャンプ" },
    { "K", "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "ホバー情報" },
    { "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", desc = "コードアクション" },
    { "<leader>cr", "<cmd>lua vim.lsp.buf.rename()<CR>", desc = "リネーム" },
  },
  config = function()
    local capabilities = require("blink.cmp").get_lsp_capabilities()

    for _, server in ipairs(tooling.lsp_servers) do
      vim.lsp.config(server.name, {
        capabilities = capabilities,
      })
      vim.lsp.enable(server.name)
    end
  end,
}
