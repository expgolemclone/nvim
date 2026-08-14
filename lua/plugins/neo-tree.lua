local symbol_kinds = {
  "Root",
  "File",
  "Module",
  "Namespace",
  "Package",
  "Class",
  "Method",
  "Property",
  "Field",
  "Constructor",
  "Enum",
  "Interface",
  "Function",
  "Variable",
  "Constant",
  "String",
  "Number",
  "Boolean",
  "Array",
  "Object",
  "Key",
  "Null",
  "EnumMember",
  "Struct",
  "Event",
  "Operator",
  "TypeParameter",
}

local document_symbol_kinds = {}
for _, kind in ipairs(symbol_kinds) do
  document_symbol_kinds[kind] = { icon = "*" }
end

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    close_if_last_window = true,
    default_component_configs = {
      indent = {
        expander_collapsed = ">",
        expander_expanded = "v",
      },
      icon = {
        folder_closed = "+",
        folder_open = "-",
        folder_empty = "+",
        folder_empty_open = "-",
        default = "*",
        provider = function() end,
      },
      git_status = {
        symbols = {
          added = "+",
          deleted = "x",
          modified = "~",
          renamed = ">",
          untracked = "?",
          ignored = "i",
          unstaged = "!",
          staged = "+",
          conflict = "!",
        },
      },
    },
    document_symbols = {
      kinds = document_symbol_kinds,
    },
  },
}
