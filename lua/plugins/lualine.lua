return {
  "nvim-lualine/lualine.nvim",
  opts = {
    options = {
      theme = "catppuccin-nvim",
      icons_enabled = false,
      component_separators = "|",
      section_separators = "",
    },
    sections = {
      lualine_x = {
        "encoding",
        {
          "fileformat",
          fmt = function(format)
            return ({ unix = "LF", dos = "CRLF", mac = "CR" })[format]
          end,
        },
        "filetype",
      },
    },
  },
}
