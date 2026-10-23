return {
  "saghen/blink.cmp",
  version = "1.*",
  dependencies = { "windwp/nvim-autopairs" },
  opts = {
    keymap = { preset = "enter" },
    sources = {
      default = { "lsp", "buffer" },
    },
    completion = {
      accept = { auto_brackets = { enabled = true } },
      documentation = { auto_show = true },
      menu = {
        draw = {
          columns = { { "label", "label_description", gap = 1 } },
        },
      },
    },
  },
}
