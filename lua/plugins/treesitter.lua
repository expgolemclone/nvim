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
  commit = "4916d6592ede8c07973490d9322f187e07dfefac",
  lazy = false,
  build = function()
    local treesitter = require("nvim-treesitter")
    treesitter.update():wait(300000)
    treesitter.install(parsers):wait(300000)
  end,
  config = function()
    local treesitter = require("nvim-treesitter")
    treesitter.setup({})

    vim.api.nvim_create_autocmd("FileType", {
      pattern = filetypes,
      callback = function(args)
        vim.treesitter.start(args.buf)
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
