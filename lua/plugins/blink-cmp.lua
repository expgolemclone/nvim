return {
  "saghen/blink.cmp",
  version = "*",
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  opts = {
    keymap = { preset = "default" },
    sources = {
      default = { "lsp", "snippets", "buffer" },
    },
    completion = {
      accept = { auto_brackets = { enabled = true } },
      documentation = { auto_show = true },
    },
  },
}
