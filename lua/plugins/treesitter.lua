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
    assert(vim.fn.executable("tree-sitter") == 1, "Install tree-sitter-cli before building parsers")
    treesitter.update():wait(300000)
    treesitter.install(parsers):wait(300000)
    for _, language in ipairs(parsers) do
      local loaded, err = vim.treesitter.language.add(language)
      assert(loaded, "Parser build failed: " .. language .. ": " .. tostring(err))
    end
  end,
  config = function()
    local treesitter = require("nvim-treesitter")
    treesitter.setup({})

    vim.api.nvim_create_autocmd("FileType", {
      pattern = filetypes,
      callback = function(args)
        -- Neovim 0.12 native ftplugins already start these highlighters.
        if vim.bo[args.buf].filetype ~= "lua" and vim.bo[args.buf].filetype ~= "markdown" then
          vim.treesitter.start(args.buf)
        end
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
