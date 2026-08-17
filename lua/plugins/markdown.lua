local callout_labels = {
  note = "Note",
  tip = "Tip",
  important = "Important",
  warning = "Warning",
  caution = "Caution",
  abstract = "Abstract",
  summary = "Summary",
  tldr = "Tldr",
  info = "Info",
  todo = "Todo",
  hint = "Hint",
  success = "Success",
  check = "Check",
  done = "Done",
  question = "Question",
  help = "Help",
  faq = "Faq",
  attention = "Attention",
  failure = "Failure",
  fail = "Fail",
  missing = "Missing",
  danger = "Danger",
  error = "Error",
  bug = "Bug",
  example = "Example",
  quote = "Quote",
  cite = "Cite",
}

local callouts = {}
for name, label in pairs(callout_labels) do
  callouts[name] = { rendered = label }
end

local link_names = {
  "web",
  "apple",
  "discord",
  "github",
  "gitlab",
  "google",
  "hackernews",
  "linkedin",
  "microsoft",
  "neovim",
  "reddit",
  "slack",
  "stackoverflow",
  "steam",
  "twitter",
  "wikipedia",
  "x",
  "youtube",
  "youtube_short",
}

local links = {}
for _, name in ipairs(link_names) do
  links[name] = { icon = "" }
end

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      completions = { lsp = { enabled = true } },
      heading = { enabled = false },
      code = {
        enabled = true,
        sign = false,
        language_icon = false,
      },
      html = {
        tag = {
          div = {},
          details = {},
          summary = {},
        },
      },
      latex = {
        enabled = true,
        converter = "latex2text",
      },
      callout = callouts,
      checkbox = {
        unchecked = { icon = "[ ]" },
        checked = { icon = "[x]" },
        custom = {
          todo = { rendered = "[-]" },
        },
      },
      link = {
        footnote = { icon = "" },
        image = "[image] ",
        image_custom = false,
        email = "@ ",
        hyperlink = "",
        wiki = { icon = "" },
        custom = links,
      },
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    init = function()
      vim.g.mkdp_auto_close = 1
    end,
  },
}
