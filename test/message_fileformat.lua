local endings = require("line_endings")
local Config = require("noice.config")
local Format = require("noice.text.format")
local Manager = require("noice.message.manager")
local Message = require("noice.message")

assert(Config.is_running(), "Noice must be running before file operations")
assert(require("noice.ui")._attached, "Noice must capture native messages")

local filename = '"notes[unix][dos][mac].txt" '
for format, label in pairs({ unix = "LF", dos = "CRLF", mac = "CR" }) do
  for _, counts in ipairs({ "2L, 12B written", "2 lines, 12 bytes appended" }) do
    local source = filename .. "[New][" .. format .. "][noeol] " .. counts
    local expected = filename .. "[New][" .. label .. "][noeol] " .. counts
    assert(endings.file_message(source) == expected, source)
    for _, kind in ipairs({ "", "progress" }) do
      local message = Message("msg_show", kind, { { 0, source } })
      for name in pairs(require("noice.config.format").builtin) do
        if vim.inspect(Config.options.format[name]):find("{file_message}", 1, true) then
          local rendered = Format.format(message, name):content()
          assert(rendered:find(expected, 1, true), name .. ": " .. rendered)
        end
      end
      assert(message:content() == source, "Formatting must not mutate message history")
    end
  end
end

for _, text in ipairs({ "example [unix]", filename .. "[dos] cannot open", filename .. "2L, 12B written" }) do
  assert(endings.file_message(text) == text, "Unrelated message was changed: " .. text)
end
local literal = filename .. "[unix] 2L, 12B written"
local highlighted = Format.format(Message("msg_show", "", { { "WarningMsg", literal } }), "notify")
assert(highlighted:content() == filename .. "[LF] 2L, 12B written")
assert(highlighted._lines[1]._texts[1].extmark.hl_group == "WarningMsg")
for _, kind in ipairs({ "echo", "emsg", "wmsg" }) do
  local message = Message("msg_show", kind, { { "ErrorMsg", literal } })
  local rendered = Format.format(message, "notify")
  assert(rendered:content() == literal, "Non-file message must stay literal")
  assert(rendered._lines[1]._texts[1].extmark.hl_group == "ErrorMsg", "Highlight was lost")
end
local history = Message("msg_history_show", "", {
  { 0, filename .. "[unix] 2L, 12B written\n" },
  { "ErrorMsg", "E212: error [dos]" },
})
local rendered_history = Format.format(history, "notify")
assert(rendered_history:content() == filename .. "[LF] 2L, 12B written\nE212: error [dos]")
assert(rendered_history._lines[2]._texts[1].extmark.hl_group == "ErrorMsg")

local function native_message_since(tick, path, marker)
  local message
  assert(
    vim.wait(3000, function()
      for _, candidate in ipairs(Manager.get({ event = "msg_show" }, { history = true, sort = true })) do
        local text = candidate:content()
        if candidate.tick > tick and text:gsub("\\", "/"):find(path, 1, true) and text:find(marker, 1, true) then
          message = candidate
        end
      end
      return message ~= nil
    end, 10),
    "No native message captured for "
      .. path
      .. " ("
      .. marker
      .. "): "
      .. vim.inspect(vim.tbl_map(function(item)
        return item:content()
      end, Manager.get({ event = "msg_show" }, { history = true, sort = true })))
  )
  return message
end

local function assert_display(message)
  local source = message:content()
  local expected = endings.file_message(source)
  local rendered = Format.format(message, "notify"):content()
  assert(rendered == expected, "Wrong message: " .. rendered)
  local flags = rendered:match('^".*"%s+(.*)$')
  for _, name in ipairs({ "unix", "dos", "mac" }) do
    assert(not flags:find("[" .. name .. "]", 1, true), rendered)
  end
  return expected
end

local function buffer_shows(text)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "noice" then
      local contents = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
      if contents:find(text, 1, true) then
        return true
      end
    end
  end
  return false
end

local original_formats = vim.o.fileformats
vim.opt.fileformats = { "unix", "dos", "mac" }
local original_shortmess = vim.o.shortmess
vim.opt.shortmess:remove("F") -- Exercise read messages even when normally suppressed.
local host_format = vim.fn.has("win32") == 1 and "dos" or "unix"
for format, separator in pairs({ unix = "\n", dos = "\r\n", mac = "\r" }) do
  local path = vim.fs.joinpath(assert(vim.env.NVIM_TEST_TMP), format .. "[unix][dos][mac].txt")
  vim.cmd.enew()
  vim.bo.swapfile = false
  vim.bo.undofile = false
  vim.bo.fileformat = format
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hello", "world" })
  local tick = Manager.tick()
  vim.cmd.write(vim.fn.fnameescape(path))
  local saved = native_message_since(tick, path, "written")
  local display = assert_display(saved)
  if format ~= host_format then
    assert(display:find("[" .. endings.labels[format] .. "]", 1, true), display)
  end
  assert(vim.bo.fileformat == format and not vim.bo.modified, "Saving changed buffer state")
  local file = assert(io.open(path, "rb"))
  local bytes = file:read("*a")
  file:close()
  assert(bytes == "hello" .. separator .. "world" .. separator, "Line endings changed on disk: " .. format)
  assert(
    vim.wait(3000, function()
      return buffer_shows(display)
    end, 10),
    "Save notification did not render: " .. display
  )

  local saved_buffer = vim.api.nvim_get_current_buf()
  vim.cmd.enew()
  vim.api.nvim_buf_delete(saved_buffer, {})
  tick = Manager.tick()
  vim.cmd.edit(vim.fn.fnameescape(path))
  local loaded = native_message_since(tick, path, "2L,")
  assert_display(loaded)
  assert(vim.bo.fileformat == format, "Read detected the wrong line endings")
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "hello", "world" }))

  tick = Manager.tick()
  vim.cmd.read(vim.fn.fnameescape(path))
  assert_display(native_message_since(tick, path, "2L,"))
  vim.cmd.undo()
  assert(not vim.bo.modified, "Undoing :read must restore the buffer state")

  local range_path = vim.fs.joinpath(vim.env.NVIM_TEST_TMP, format .. "-range.txt")
  tick = Manager.tick()
  vim.cmd("1write " .. vim.fn.fnameescape(range_path))
  assert_display(native_message_since(tick, range_path, "written"))
  tick = Manager.tick()
  vim.cmd("2write >> " .. vim.fn.fnameescape(range_path))
  assert_display(native_message_since(tick, range_path, "appended"))
  file = assert(io.open(range_path, "rb"))
  bytes = file:read("*a")
  file:close()
  assert(bytes == "hello" .. separator .. "world" .. separator, "Range write/append changed line endings")

  vim.cmd("messages")
  assert(
    vim.wait(3000, function()
      return buffer_shows(display)
    end, 10),
    ":messages did not render normalized history"
  )
  require("noice").cmd("dismiss")
  -- Close history splits so the next fixture is edited in the original window.
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "noice" then
      vim.api.nvim_win_close(win, true)
    end
  end
  io.write("  OK    native file messages: " .. format .. "\n")
end
vim.o.fileformats = original_formats
vim.o.shortmess = original_shortmess

-- A real failed save must still fail and must not report a successful write.
vim.cmd.enew()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unsaved" })
local missing = vim.fs.joinpath(vim.env.NVIM_TEST_TMP, "missing", "failed.txt")
local ok, err = pcall(vim.cmd.write, vim.fn.fnameescape(missing))
assert(not ok and tostring(err):find("E212", 1, true), "Failed write must keep its native error")
assert(vim.bo.modified, "Failed write cleared the modified flag")
local failed_buffer = vim.api.nvim_get_current_buf()
local tick = Manager.tick()
local command = ":write " .. vim.fn.fnameescape(missing) .. "<CR>"
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(command, true, false, true), "nx", false)
local error_message
assert(
  vim.wait(3000, function()
    for _, candidate in ipairs(Manager.get({ error = true }, { history = true })) do
      if candidate.tick > tick and candidate:content():find("E212", 1, true) then
        error_message = candidate
      end
    end
    return error_message ~= nil
  end, 10),
  "Native failed-write error was not captured"
)
assert(Format.format(error_message, "notify"):content() == error_message:content())
assert(
  vim.wait(3000, function()
    return buffer_shows("E212")
  end, 10),
  "Native failed-write error was not displayed"
)
assert(vim.bo[failed_buffer].modified, "Interactive failed write cleared the modified flag")

io.write("File-message line-ending check passed\n")
