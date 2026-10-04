return {
  "folke/noice.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    cmdline = {
      view = "cmdline",
      format = {
        cmdline = { icon = ":" },
        search_down = { icon = "/" },
        search_up = { icon = "?" },
        filter = { icon = "$" },
        lua = { icon = "lua" },
        help = { icon = "help" },
        calculator = { icon = "=" },
        input = { icon = ">" },
      },
    },
    messages = { view = "mini", view_error = "popup", view_warn = "mini" },
    popupmenu = { enabled = false },
    notify = { enabled = false, view = "mini" },
    lsp = {
      progress = { enabled = false },
      hover = { enabled = false },
      signature = { enabled = false },
      message = { enabled = false },
    },
    format = { level = { icons = { error = "E", warn = "W", info = "I" } } },
    routes = {
      -- Neovim 0.12 emits a filename-only progress update before the write result.
      {
        filter = { event = "msg_show", kind = "progress", find = '^".*"%s*$' },
        opts = { skip = true },
      },
      { filter = { event = "msg_show", kind = "progress" }, view = "mini" },
    },
  },
  config = function(_, opts)
    local formatters = require("noice.text.format.formatters")
    local line_endings = require("line_endings")
    -- Add a formatter rather than replacing any Noice implementation.
    formatters.file_message = function(message, options, input)
      local file_info = input.event == "msg_history_show"
        or (input.event == "msg_show" and (input.kind == "" or input.kind == "progress"))
      if not file_info then
        return formatters.message(message, options, input)
      end
      for index, line in ipairs(input._lines) do
        if index > 1 then
          message:newline()
        end
        local text = line:content()
        local formatted = line_endings.file_message(text)
        if formatted == text then
          message:append(line)
        else
          message:append(formatted, options.hl_group or line._texts[1].extmark)
        end
      end
    end
    -- Use the same formatter in notifications, :messages, and history pickers.
    for name, entries in pairs(require("noice.config.format").builtin) do
      local format = vim.deepcopy(entries)
      for index, entry in ipairs(format) do
        if type(entry) == "string" then
          format[index] = entry:gsub("{message}", "{file_message}")
        elseif type(entry[1]) == "string" then
          entry[1] = entry[1]:gsub("{message}", "{file_message}")
        end
      end
      opts.format[name] = format
    end
    require("noice").setup(opts)
  end,
}
