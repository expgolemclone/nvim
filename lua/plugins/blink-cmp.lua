return {
  "saghen/blink.cmp",
  version = "1.*",
  dependencies = { "windwp/nvim-autopairs" },
  opts = {
    keymap = {
      preset = "default",
      ["<CR>"] = {
        "accept",
        function()
          return require("markdown_enter").continue_marker() or require("nvim-autopairs").autopairs_cr()
        end,
      },
    },
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
