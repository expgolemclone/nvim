return {
  "saghen/blink.cmp",
  version = "*",
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  opts = {
    keymap = {
      preset = "default",
      ["<CR>"] = {
        "accept",
        function()
          return require("markdown_enter").continue_marker()
        end,
        "fallback",
      },
    },
    sources = {
      default = { "lsp", "snippets", "buffer" },
    },
    completion = {
      accept = { auto_brackets = { enabled = true } },
      documentation = { auto_show = true },
    },
  },
}
