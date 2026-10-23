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

return {
  "nvim-treesitter/nvim-treesitter",
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
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        local filetype = vim.bo[args.buf].filetype
        if not vim.list_contains(parsers, vim.treesitter.language.get_lang(filetype)) then
          return
        end
        -- Neovim 0.12 native ftplugins already start these highlighters.
        if filetype ~= "lua" and filetype ~= "markdown" then
          vim.treesitter.start(args.buf)
        end
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
