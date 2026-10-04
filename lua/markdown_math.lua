-- Nabla supplies formula drawings; Neovim display cells determine placement.
local M = {}
M.ns = vim.api.nvim_create_namespace("markdown_math")

local function width(text)
  return vim.fn.strdisplaywidth(text)
end

local function chunks_text(chunks)
  local result = {}
  for _, chunk in ipairs(chunks or {}) do
    result[#result + 1] = chunk[1]
  end
  return table.concat(result)
end

-- Extmark columns are bytes, while virtual-line padding is terminal cells.
local function prefix_width(buf, row, stop)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  local replacements, insertions = {}, {}
  vim.treesitter.get_parser(buf, "markdown"):for_each_tree(function(tree, language)
    local query = vim.treesitter.query.get(language:lang(), "highlights")
    if query then
      for id, node, metadata in query:iter_captures(tree:root(), buf, row, row + 1) do
        local conceal = (metadata[id] or {}).conceal or metadata.conceal
        local sr, sc, er, ec = node:range()
        if conceal ~= nil and sr == row and er == row and sc < stop then
          replacements[sc] = { finish = ec, text = conceal }
        end
      end
    end
  end)
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, { row, 0 }, { row, stop }, { details = true })) do
    local col, details = mark[3], mark[4]
    if col < stop then
      if details.conceal ~= nil and details.end_row == row and details.end_col > col then
        replacements[col] = { finish = details.end_col, text = details.conceal }
      end
      if details.virt_text_pos == "inline" then
        insertions[col] = (insertions[col] or "") .. chunks_text(details.virt_text)
      end
    end
  end
  local col, displayed = 0, {}
  while col < stop do
    displayed[#displayed + 1] = insertions[col] or ""
    local replacement = replacements[col]
    if replacement then
      displayed[#displayed + 1] = replacement.text
      col = replacement.finish
    else
      local char = vim.fn.strcharpart(line:sub(col + 1), 0, 1)
      displayed[#displayed + 1] = char
      col = col + #char
    end
  end
  return width(table.concat(displayed))
end

local function formula_nodes(buf)
  local parser = vim.treesitter.get_parser(buf, "markdown")
  parser:parse(true)
  local nodes, seen = {}, {}
  parser:for_each_tree(function(tree, language)
    if language:lang() == "latex" then
      local node = tree:root()
      local key = table.concat({ node:range() }, ":")
      if not seen[key] then
        seen[key] = true
        nodes[#nodes + 1] = node
      end
    end
  end)
  table.sort(nodes, function(a, b)
    local ar, ac = a:range()
    local br, bc = b:range()
    return ar < br or (ar == br and ac < bc)
  end)
  return nodes
end

local function drawing(node, buf)
  local text = vim.treesitter
    .get_node_text(node, buf)
    :gsub("%$", "")
    :gsub("^\\%[", "")
    :gsub("\\%]$", "")
    :gsub("^\\%(", "")
    :gsub("\\%)$", "")
  local ok, expression = pcall(require("nabla.latex").parse_all, vim.trim(text))
  if not ok or not expression then
    return nil
  end
  local success, grid = pcall(require("nabla.ascii").to_ascii, { expression }, 1)
  if not success or not grid or grid == "" then
    return nil
  end
  local lines = {}
  for line in vim.gsplit(tostring(grid), "\n", { plain = true }) do
    local chunks = {}
    for char in line:gmatch("[\1-\127\194-\244][\128-\191]*") do
      local highlight = char:match("%d") and "@number" or char:match("%a") and "@string" or "@operator"
      chunks[#chunks + 1] = { char, highlight }
    end
    lines[#lines + 1] = chunks
  end
  return lines, grid.my + 1
end

local function add_line(target, index, padding, chunks)
  target[index] = target[index] or {}
  local line = target[index]
  local gap = padding - width(chunks_text(line))
  if gap > 0 then
    line[#line + 1] = { string.rep(" ", gap), "Normal" }
  end
  vim.list_extend(line, chunks)
end

function M.clear(buf)
  vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
end

function M.render(buf)
  M.clear(buf)
  local virtual = {}
  for _, node in ipairs(formula_nodes(buf)) do
    local lines, baseline = drawing(node, buf)
    if lines then
      local sr, sc, er, ec = node:range()
      local row, col = sr, sc
      if sr ~= er then
        -- Anchor display math to its first body line, not the $$ delimiter.
        row, col = sr + 1, 0
      end
      local padding = prefix_width(buf, row, col)
      for r = sr, er do
        local first = r == sr and sc or 0
        local last = r == er and ec or #vim.api.nvim_buf_get_lines(buf, r, r + 1, false)[1]
        if last > first then
          vim.api.nvim_buf_set_extmark(buf, M.ns, r, first, {
            end_row = r,
            end_col = last,
            conceal = "",
          })
        end
      end
      vim.api.nvim_buf_set_extmark(buf, M.ns, row, col, {
        virt_text = lines[baseline],
        virt_text_pos = "inline",
      })
      virtual[row] = virtual[row] or { above = {}, below = {} }
      for index, chunks in ipairs(lines) do
        if index < baseline then
          add_line(virtual[row].above, baseline - index, padding, chunks)
        elseif index > baseline then
          add_line(virtual[row].below, index - baseline, padding, chunks)
        end
      end
    end
  end
  for row, layout in pairs(virtual) do
    for _, side in ipairs({ "above", "below" }) do
      local lines = layout[side]
      if side == "above" then
        local reversed = {}
        for index = #lines, 1, -1 do
          reversed[#reversed + 1] = lines[index]
        end
        lines = reversed
      end
      if #lines > 0 then
        vim.api.nvim_buf_set_extmark(buf, M.ns, row, 0, {
          virt_lines = lines,
          virt_lines_above = side == "above",
        })
      end
    end
  end
end

return M
