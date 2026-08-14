local function normal_enter()
  return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
end

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
          return require("markdown_enter").continue_marker() or normal_enter()
        end,
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
