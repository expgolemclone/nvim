local function fail(message)
  error(message, 0)
end

local function load_plugin()
  local ok, lazy = pcall(require, "lazy")
  if not ok then
    fail("lazy.nvim is not available")
  end
  lazy.load({ plugins = { "render-markdown.nvim" } })

  local ok_rm, rm = pcall(require, "render-markdown")
  if not ok_rm then
    fail("render-markdown.nvim is not available")
  end
  return rm
end

local function parser_available(language)
  return pcall(vim.treesitter.language.inspect, language)
end

local function read_source(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
end

local function has_math_source(source)
  for line in (source .. "\n"):gmatch("(.-)\n") do
    local without_escaped = line:gsub("\\%$", "")
    if without_escaped:find("%$.-%$") then
      return true
    end
  end
  return false
end

local function has_html_source(source)
  return source:find("<[%a][%w:_%-]*%s[^>]*>") ~= nil
    or source:find("<[%a][%w:_%-]*>") ~= nil
end

local capture_sources = {
  markdown = [[
    (fenced_code_block) @code

    [
      (thematic_break)
      (minus_metadata)
      (plus_metadata)
    ] @dash

    (link_reference_definition (link_label) @footnote)

    [
      (atx_heading)
      (setext_heading)
    ] @heading

    (list_item) @list
    (block_quote) @quote
    (pipe_table) @table
  ]],
  markdown_inline = [[
    (code_span) @code

    ((inline) @highlight
      (#lua-match? @highlight "==[^=]+=="))

    [
      (email_autolink)
      (full_reference_link)
      (image)
      (inline_link)
      (uri_autolink)
    ] @link

    (shortcut_link) @shortcut
  ]],
  html = [[
    (comment) @comment
    (element) @tag
  ]],
  yaml = [[
    (block_sequence_item) @bullet

    ((double_quote_scalar) @link
      (#lua-match? @link "^\"%[%[.+%]%]\"$"))
  ]],
}

local function capture_query(language)
  local source = capture_sources[language]
  if not source then
    return nil
  end
  local ok, query = pcall(vim.treesitter.query.parse, language, source)
  if not ok then
    fail(("unable to parse %s invariant query: %s"):format(language, query))
  end
  return query
end

local function range_key(item)
  return table.concat({
    item.language,
    item.capture,
    item.start_row,
    item.start_col,
    item.end_row,
    item.end_col,
  }, ":")
end

local function collect_items(buf, parser)
  local items = {}
  local seen = {}
  local languages_seen = {}
  local query_cache = {}

  parser:parse(true)
  parser:for_each_tree(function(tree, language_tree)
    local language = language_tree:lang()
    languages_seen[language] = true
    local root = tree:root()

    if language == "latex" then
      local start_row, start_col, end_row, end_col = root:range()
      local item = {
        language = language,
        capture = "math",
        start_row = start_row,
        start_col = start_col,
        end_row = end_row,
        end_col = end_col,
        text = vim.treesitter.get_node_text(root, buf) or "",
      }
      local key = range_key(item)
      if not seen[key] then
        seen[key] = true
        items[#items + 1] = item
      end
      return
    end

    local source = capture_sources[language]
    if not source then
      return
    end
    if not query_cache[language] then
      query_cache[language] = capture_query(language)
    end
    local query = query_cache[language]

    for id, node in query:iter_captures(root, buf, 0, -1) do
      local capture = query.captures[id]
      local start_row, start_col, end_row, end_col = node:range()
      local item = {
        language = language,
        capture = capture,
        start_row = start_row,
        start_col = start_col,
        end_row = end_row,
        end_col = end_col,
        text = vim.treesitter.get_node_text(node, buf) or "",
      }
      local key = range_key(item)
      if not seen[key] then
        seen[key] = true
        items[#items + 1] = item
      end
    end
  end)

  table.sort(items, function(a, b)
    if a.start_row ~= b.start_row then
      return a.start_row < b.start_row
    end
    if a.start_col ~= b.start_col then
      return a.start_col < b.start_col
    end
    if a.end_row ~= b.end_row then
      return a.end_row < b.end_row
    end
    return a.capture < b.capture
  end)
  return items, languages_seen
end

local function code_highlight_stats(buf, parser, language)
  local query = vim.treesitter.query.get(language, "highlights")
  if not query then
    fail(("no Tree-sitter highlight query is available for %s"):format(language))
  end

  local captures = {}
  local foregrounds = {}
  parser:for_each_tree(function(tree, language_tree)
    if language_tree:lang() ~= language then
      return
    end

    for id, node in query:iter_captures(tree:root(), buf, 0, -1) do
      local text = vim.treesitter.get_node_text(node, buf) or ""
      if text:find("%S") then
        local capture = query.captures[id]
        captures[capture] = true
        local highlight = vim.api.nvim_get_hl(0, {
          name = ("@%s.%s"):format(capture, language),
          link = false,
        })
        if highlight.fg then
          foregrounds[highlight.fg] = true
        end
      end
    end
  end)

  return vim.tbl_count(captures), vim.tbl_count(foregrounds)
end

local function is_checkbox(text)
  return text:match("^%s*[-+*]%s+%[[ xX%-]%]") ~= nil
    or text:match("^%s*%d+[%.%)]%s+%[[ xX%-]%]") ~= nil
end

local function html_tag(text)
  return text:match("^<%s*([%w:_%-]+)")
end

local function enabled_for(item, config)
  local language = item.language
  local capture = item.capture

  if language == "markdown" then
    if capture == "code" then
      return config.code.enabled, "code"
    elseif capture == "dash" then
      return config.dash.enabled, "dash"
    elseif capture == "footnote" then
      return config.link.enabled and config.link.footnote.enabled, "footnote"
    elseif capture == "heading" then
      return config.heading.enabled, "heading"
    elseif capture == "list" then
      if is_checkbox(item.text) then
        return config.checkbox.enabled, "checkbox"
      end
      return config.bullet.enabled, "list"
    elseif capture == "quote" then
      return config.quote.enabled, "quote"
    elseif capture == "table" then
      return config.pipe_table.enabled, "table"
    end
  elseif language == "markdown_inline" then
    if capture == "code" then
      return config.code.enabled, "inline_code"
    elseif capture == "highlight" then
      return config.inline_highlight.enabled, "inline_highlight"
    elseif capture == "link" then
      return config.link.enabled, "link"
    elseif capture == "shortcut" then
      local body = item.text:match("^%[(.*)%]$") or item.text
      if body == " " or body == "x" or body == "X" or body == "-" then
        return false, "checkbox_shortcut"
      end
      if body:sub(1, 1) == "!" then
        return false, "callout_shortcut"
      end
      return config.link.enabled, "shortcut"
    end
  elseif language == "html" then
    if not config.html.enabled then
      return false, "html"
    end
    if capture == "comment" then
      return config.html.comment.conceal, "html_comment"
    elseif capture == "tag" then
      local tag = html_tag(item.text)
      return tag ~= nil and config.html.tag[tag] ~= nil, "html_tag"
    end
  elseif language == "yaml" then
    if capture == "bullet" then
      return config.yaml.enabled, "yaml_bullet"
    elseif capture == "link" then
      return config.yaml.enabled and config.link.enabled, "yaml_link"
    end
  elseif language == "latex" and capture == "math" then
    return config.latex.enabled, "latex"
  end

  fail(("missing invariant mapping for %s:%s"):format(language, capture))
end

local function pos_less(a_row, a_col, b_row, b_col)
  return a_row < b_row or (a_row == b_row and a_col < b_col)
end

local function point_in_item(row, col, item)
  local after_start = not pos_less(row, col, item.start_row, item.start_col)
  local before_end = pos_less(row, col, item.end_row, item.end_col)
  return after_start and before_end
end

local function mark_overlaps(mark, item)
  local row, col, details = mark[2], mark[3], mark[4]
  local end_row, end_col = details.end_row, details.end_col
  if end_row == nil or end_col == nil then
    return point_in_item(row, col, item)
  end
  return pos_less(row, col, item.end_row, item.end_col)
    and pos_less(item.start_row, item.start_col, end_row, end_col)
end

local function chunks_have_text(lines)
  if type(lines) ~= "table" then
    return false
  end
  for _, line in ipairs(lines) do
    if type(line) == "table" then
      if type(line[1]) == "string" then
        if line[1] ~= "" then
          return true
        end
      elseif chunks_have_text(line) then
        return true
      end
    end
  end
  return false
end

local function mark_is_visual(mark)
  local details = mark[4]
  return details.conceal ~= nil
    or details.conceal_lines ~= nil
    or details.hl_group ~= nil
    or details.line_hl_group ~= nil
    or details.number_hl_group ~= nil
    or (details.sign_text ~= nil and details.sign_text ~= "")
    or chunks_have_text(details.virt_text)
    or chunks_have_text(details.virt_lines)
end

local function center_item(win, item)
  local row = math.min(item.start_row + 1, vim.api.nvim_buf_line_count(0))
  vim.api.nvim_win_set_cursor(win, { row, 0 })
  vim.cmd("normal! zz")
  vim.cmd("redraw")
end

local function screen_signature(win, item)
  center_item(win, item)
  local result = {}
  local last_row = math.max(1, vim.o.lines - 2)
  for screen_row = 1, last_row do
    local cells = {}
    for screen_col = 1, vim.o.columns do
      local char = vim.fn.screenstring(screen_row, screen_col)
      local attr = vim.fn.screenattr(screen_row, screen_col)
      cells[#cells + 1] = char .. "\31" .. tostring(attr)
    end
    result[#result + 1] = table.concat(cells, "\30")
  end
  return table.concat(result, "\29")
end

local function render_and_wait(rm, buf, win, context)
  local decorator = require("render-markdown.core.ui").get(buf)
  local previous = decorator.n
  rm.render({ buf = buf, win = win, event = "InvariantTest" })
  if not vim.wait(5000, function()
    return decorator.n > previous
  end, 10) then
    fail(("timed out waiting for render-markdown update: %s"):format(context))
  end
  vim.cmd("redraw")
end

local function disable_and_wait(rm, buf)
  local ui = require("render-markdown.core.ui")
  rm.buf_disable()
  if not vim.wait(5000, function()
    return #vim.api.nvim_buf_get_extmarks(buf, ui.ns, 0, -1, {}) == 0
  end, 10) then
    fail("timed out waiting for render-markdown disable")
  end
  vim.cmd("redraw")
end

local function enable_and_wait(rm, buf)
  local decorator = require("render-markdown.core.ui").get(buf)
  local previous = decorator.n
  rm.buf_enable()
  if not vim.wait(5000, function()
    return decorator.n > previous
  end, 10) then
    fail("timed out waiting for render-markdown enable")
  end
  vim.cmd("redraw")
end

local function excerpt(item)
  local line = vim.api.nvim_buf_get_lines(0, item.start_row, item.start_row + 1, false)[1] or ""
  line = vim.trim(line)
  if #line > 100 then
    line = line:sub(1, 97) .. "..."
  end
  return line
end

local function main()
  vim.o.columns = 120
  vim.o.lines = 45
  vim.o.wrap = false

  local rm = load_plugin()
  local state = require("render-markdown.state")
  state.config.anti_conceal.enabled = false
  state.config.debounce = 0
  state.cache = {}

  local root = vim.env.NVIM_CONFIG_CHECKOUT or vim.fn.getcwd()
  local fixture = vim.fs.joinpath(root, "test.md")
  vim.cmd.edit(vim.fn.fnameescape(fixture))
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  if vim.bo[buf].filetype ~= "markdown" then
    fail(("test.md filetype is %q, expected markdown"):format(vim.bo[buf].filetype))
  end

  local code_languages = { "javascript", "python", "bash" }
  local required_languages = { "markdown", "markdown_inline", "html" }
  vim.list_extend(required_languages, code_languages)
  for _, language in ipairs(required_languages) do
    if not parser_available(language) then
      fail(("required Tree-sitter parser is unavailable: %s"):format(language))
    end
  end

  pcall(vim.treesitter.start, buf, "markdown")
  vim.wait(50)

  local config = state.get(buf)
  local source = read_source(buf)
  local math_source = has_math_source(source)
  if config.latex.enabled and math_source then
    if not parser_available("latex") then
      fail("LaTeX syntax exists, but the latex Tree-sitter parser is unavailable")
    end
    local commands = require("render-markdown.lib.env").commands(config.latex.converter)
    if #commands == 0 then
      fail(("LaTeX syntax exists, but no configured converter is executable: %s"):format(vim.inspect(config.latex.converter)))
    end
  end

  render_and_wait(rm, buf, win, "initial render")

  local parser = vim.treesitter.get_parser(buf, "markdown")
  local items, languages_seen = collect_items(buf, parser)
  if #items == 0 then
    fail("no renderable Markdown syntax was discovered in test.md")
  end
  if not languages_seen.markdown_inline then
    fail("test.md contains inline Markdown, but no markdown_inline syntax tree was produced")
  end
  if config.html.enabled and has_html_source(source) and not languages_seen.html then
    fail("test.md contains HTML, but no injected html syntax tree was produced")
  end
  local code_stats = {}
  for _, language in ipairs(code_languages) do
    if not languages_seen[language] then
      fail(("test.md contains a %s code fence, but no injected syntax tree was produced"):format(language))
    end
    local capture_count, foreground_count = code_highlight_stats(buf, parser, language)
    code_stats[language] = {
      captures = capture_count,
      foregrounds = foreground_count,
    }
    if capture_count < 3 then
      fail(("%s code has only %d semantic highlight capture(s), expected at least 3"):format(language, capture_count))
    end
    if foreground_count < 3 then
      fail(("%s code resolves to only %d foreground color(s), expected at least 3"):format(language, foreground_count))
    end
  end
  if config.latex.enabled and math_source and not languages_seen.latex then
    fail("LaTeX syntax exists, but no injected latex syntax tree was produced")
  end

  local ui = require("render-markdown.core.ui")
  local failures = {}
  local stats = {}

  local function stat_for(component)
    if not stats[component] then
      stats[component] = {
        total = 0,
        enabled = 0,
        skipped = 0,
        marked = 0,
        visual_candidate = false,
        screen_diff = false,
      }
    end
    return stats[component]
  end

  for _, item in ipairs(items) do
    local enabled, component = enabled_for(item, config)
    local stat = stat_for(component)
    stat.total = stat.total + 1
    if not enabled then
      stat.skipped = stat.skipped + 1
    else
      stat.enabled = stat.enabled + 1
      center_item(win, item)
      render_and_wait(rm, buf, win, ("%s line %d"):format(component, item.start_row + 1))

      local marks = vim.api.nvim_buf_get_extmarks(buf, ui.ns, 0, -1, { details = true })
      local overlapping = {}
      local visual = false
      local rendered_math = false
      for _, mark in ipairs(marks) do
        if mark_overlaps(mark, item) then
          overlapping[#overlapping + 1] = mark
          visual = visual or mark_is_visual(mark)
          rendered_math = rendered_math
            or chunks_have_text(mark[4].virt_text)
            or chunks_have_text(mark[4].virt_lines)
        end
      end

      if #overlapping == 0 then
        failures[#failures + 1] = {
          component = component,
          line = item.start_row + 1,
          reason = "no render-markdown extmark overlaps this syntax node",
          excerpt = excerpt(item),
        }
      else
        stat.marked = stat.marked + 1
      end

      if component == "latex" and not rendered_math then
        failures[#failures + 1] = {
          component = component,
          line = item.start_row + 1,
          reason = "no converted math text was rendered",
          excerpt = excerpt(item),
        }
      end

      if visual and not stat.screen_diff then
        stat.visual_candidate = true
        local rendered = screen_signature(win, item)
        disable_and_wait(rm, buf)
        local raw = screen_signature(win, item)
        enable_and_wait(rm, buf)

        if rendered ~= raw then
          stat.screen_diff = true
        end
      end
    end
  end

  for component, stat in pairs(stats) do
    if stat.enabled > 0 and stat.visual_candidate and not stat.screen_diff then
      failures[#failures + 1] = {
        component = component,
        line = nil,
        reason = "visual extmarks were created, but rendered and disabled screens were identical for every candidate",
        excerpt = nil,
      }
    end
  end

  local components = vim.tbl_keys(stats)
  table.sort(components)

  print("render-markdown invariants")
  for _, language in ipairs(code_languages) do
    local stat = code_stats[language]
    print(("  PASS  syntax_%-13s captures %d, foregrounds %d"):format(language, stat.captures, stat.foregrounds))
  end
  for _, component in ipairs(components) do
    local stat = stats[component]
    local status = "PASS"
    if stat.enabled == 0 then
      status = "SKIP"
    elseif stat.marked ~= stat.enabled then
      status = "FAIL"
    elseif stat.visual_candidate and not stat.screen_diff then
      status = "FAIL"
    end
    print(("  %-4s  %-20s marked %d/%d, skipped %d"):format(
      status,
      component,
      stat.marked,
      stat.enabled,
      stat.skipped
    ))
  end

  if #failures > 0 then
    print("")
    print(("%d rendering invariant(s) failed:"):format(#failures))
    for _, failure in ipairs(failures) do
      local location = failure.line and (" line %d"):format(failure.line) or ""
      print(("  FAIL  %s%s - %s"):format(failure.component, location, failure.reason))
      if failure.excerpt and failure.excerpt ~= "" then
        print("        " .. failure.excerpt)
      end
    end
    vim.cmd("cquit")
    return
  end

  print("")
  print(("All %d discovered renderable syntax node(s) satisfy the rendering invariants."):format(#items))
  vim.cmd("qa!")
end

local ok, err = xpcall(main, debug.traceback)
if not ok then
  print("render-markdown invariants: fatal error")
  print(err)
  vim.cmd("cquit")
end
