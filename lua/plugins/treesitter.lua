local parsers = {
  "bash",
  "css",
  "dockerfile",
  "html",
  "javascript",
  "json",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "tsx",
  "typescript",
  "yaml",
}

local filetypes = {
  "bash",
  "css",
  "dockerfile",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "lua",
  "markdown",
  "python",
  "sh",
  "typescript",
  "typescriptreact",
  "yaml",
}

return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local treesitter = require("nvim-treesitter")
    treesitter.setup({})
    treesitter.install(parsers):wait(300000)

    vim.api.nvim_create_autocmd("FileType", {
      pattern = filetypes,
      callback = function(args)
        vim.treesitter.start(args.buf)
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
