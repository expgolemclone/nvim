local function private_use_codepoint(codepoint)
  return (codepoint >= 0xE000 and codepoint <= 0xF8FF)
    or (codepoint >= 0xF0000 and codepoint <= 0xFFFFD)
    or (codepoint >= 0x100000 and codepoint <= 0x10FFFD)
end

local function assert_no_private_use(text, context)
  for index = 0, vim.fn.strchars(text) - 1 do
    local character = vim.fn.strcharpart(text, index, 1)
    local codepoint = vim.fn.char2nr(character)
    assert(not private_use_codepoint(codepoint), ("%s contains private-use glyph U+%X"):format(context, codepoint))
  end
end

local function check_strings(value, context)
  if type(value) == "string" then
    assert_no_private_use(value, context)
    return
  end

  if type(value) ~= "table" then
    return
  end

  for key, child in pairs(value) do
    check_strings(child, ("%s.%s"):format(context, key))
  end
end

local fixture = vim.fs.joinpath(vim.fn.getcwd(), "test", "sample.md")
assert(vim.fn.filereadable(fixture) == 1, "Rendering fixture is missing: " .. fixture)
vim.cmd.edit(vim.fn.fnameescape(fixture))
vim.wait(2000, function()
  return next(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })) ~= nil
end)

local extmarks = vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })
check_strings(extmarks, "markdown extmarks")

local markdown_config = require("render-markdown.state").get(0)
check_strings(markdown_config.callout, "markdown callouts")
check_strings(markdown_config.checkbox, "markdown checkboxes")
check_strings(markdown_config.link, "markdown links")

local statusline = vim.api.nvim_eval_statusline(vim.o.statusline, { winid = 0 }).str
assert_no_private_use(statusline, "statusline")

print("UI glyph check passed")
vim.cmd("qa!")
