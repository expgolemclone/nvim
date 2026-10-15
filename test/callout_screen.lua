return function(rm, render_and_wait, disable_and_wait, enable_and_wait)
  local config = require("render-markdown.state").get(vim.api.nvim_get_current_buf())
  assert(config.anti_conceal.enabled, "Callout checks require the configured anti-conceal behavior")
  for _, language in ipairs({ "markdown", "markdown_inline" }) do
    assert(pcall(vim.treesitter.language.inspect, language), "Missing callout parser: " .. language)
  end

  local names = vim.tbl_keys(config.callout)
  table.sort(names)
  assert(#names > 0, "No configured callouts to check")
  local variants = {
    { name = "plain" },
    { name = "lowercase", lowercase = true },
    { name = "nested", nested = true },
    { name = "title", title = "Custom title" },
    { name = "short-title", title = "X" },
    { name = "japanese-title", title = "日本語" },
  }
  local checks = 0
  for index, name in ipairs(names) do
    for _, variant in ipairs(variants) do
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      local win = vim.api.nvim_get_current_win()
      local callout = config.callout[name]
      local raw = variant.lowercase and callout.raw:lower() or callout.raw
      local title = variant.title
      local quote = variant.nested and "> > " or "> "
      local rendered_quote = variant.nested and "▋ ▋ " or "▋ "
      local source = { "Cursor outside callout", "", "", quote .. "Body text", "", "After callout" }
      local context = name .. "/" .. variant.name

      local function set_header()
        source[3] = quote .. raw .. (title and " " .. title or "")
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, source)
      end

      local function assert_line(row, expected, phase)
        vim.cmd("redraw")
        local pos = vim.fn.screenpos(win, row, 1)
        assert(pos.row > 0, "Callout is offscreen: " .. context .. "/" .. phase)
        local cells = {}
        for col = pos.col, vim.o.columns do
          cells[#cells + 1] = vim.fn.screenstring(pos.row, col)
        end
        local actual = vim.trim(table.concat(cells))
        assert(actual == expected, ("%s/%s: expected %q, got %q"):format(context, phase, expected, actual))
        assert(
          vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), source),
          "Rendering modified callout source"
        )
        checks = checks + 1
      end

      local function assert_rendered(phase)
        local label = title and ("* " .. title) or callout.rendered
        assert_line(3, rendered_quote .. label, phase)
        assert_line(4, rendered_quote .. "Body text", phase .. "/body")
      end

      set_header()
      vim.bo[buf].filetype = "markdown"
      vim.treesitter.start(buf, "markdown")
      vim.api.nvim_win_set_cursor(win, { 1, 0 })
      render_and_wait(rm, buf, win, context)
      assert_rendered("initial")

      -- Renderer anti-conceal exposes source; Tree-sitter still conceals the brackets.
      vim.api.nvim_win_set_cursor(win, { 3, 0 })
      render_and_wait(rm, buf, win, context .. "/cursor-on-header")
      assert_line(3, quote .. raw:sub(2, -2) .. (title and " " .. title or ""), "cursor-on-header")
      vim.api.nvim_win_set_cursor(win, { 1, 0 })
      render_and_wait(rm, buf, win, context .. "/cursor-away")
      assert_rendered("cursor-away")

      disable_and_wait(rm, buf)
      assert_line(3, source[3], "disabled")
      assert_line(4, source[4], "disabled/body")
      enable_and_wait(rm, buf)
      assert_rendered("reenabled")

      title = "A longer edited title"
      set_header()
      render_and_wait(rm, buf, win, context .. "/title-edit")
      assert_rendered("title-edit")
      callout = config.callout[names[index % #names + 1]]
      raw = callout.raw
      title = "X"
      set_header()
      render_and_wait(rm, buf, win, context .. "/type-edit")
      assert_rendered("type-edit")
      title = nil
      set_header()
      render_and_wait(rm, buf, win, context .. "/remove-title")
      assert_rendered("remove-title")
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  print(
    ("  PASS  callout_screen       %d types, %d variants, %d exact-screen checks"):format(#names, #variants, checks)
  )
end
