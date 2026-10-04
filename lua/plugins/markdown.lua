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

local function in_markdown_window(context, callback)
  vim.api.nvim_win_call(context.win, function()
    assert(vim.api.nvim_get_current_buf() == context.buf, "render-markdown callback buffer mismatch")
    callback()
  end)
end

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "jbyuki/nabla.nvim",
    },
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
        enabled = false,
      },
      win_options = {
        conceallevel = {
          default = vim.o.conceallevel,
          rendered = 2,
        },
        concealcursor = {
          default = vim.o.concealcursor,
          rendered = "nc",
        },
      },
      on = {
        render = function(context)
          in_markdown_window(context, function()
            require("markdown_math").render(context.buf)
          end)
        end,
        clear = function(context)
          in_markdown_window(context, function()
            require("markdown_math").clear(context.buf)
          end)
        end,
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
