-- Rounded box around fenced code blocks for render-markdown.nvim.
--
-- render-markdown.nvim can only draw a fenced code block as a filled
-- background plus optional single-character lines above and below it; there
-- is no built-in way to draw a bordered box. This module is a custom handler
-- (see doc/custom-handlers.md in the plugin) that is registered with
-- `extends = true`, so the builtin markdown handler still runs (headings,
-- lists, tables, concealing of the ``` fences, ...) and this one only adds
-- the box. The builtin decorations that would clash with the box must be
-- switched off in the plugin config: `code.disable_background = true`,
-- `code.border = "none"`, `code.language = false`, `code.sign = false`.
-- See lua/plugins/markdown.lua.
--
-- Layout, for a block whose widest line is W cells wide:
--
--   ╭─ 󰢱 lua ──────────╮   overlay on the opening ``` line
--   │ local x = 1      │   "│ " inline virtual text + "│" at a fixed column
--   ╰──────────────────╯   overlay on the closing ``` line
--
-- Markdown buffers do not soft wrap (see lua/config/autocmds.lua), so the
-- right edge can sit at a fixed window column. The top and bottom lines are
-- hidden while the cursor is on them (the raw ``` fence shows instead), the
-- side bars are not, so the code text never shifts under the cursor.

local M = {}

-- Highlight group for the box. FloatBorder matches LazyVim's rounded floats.
M.highlight = "FloatBorder"

-- Rows above / below the viewport that are still rendered, mirrors the
-- plugin's own overscan so blocks appear before they scroll into view.
local OVERSCAN = 10

local query ---@type vim.treesitter.Query?

---@param buf integer
---@return integer[][] 0-based inclusive row ranges currently displayed
local function visible_ranges(buf)
  local ranges = {}
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    local info = vim.fn.getwininfo(win)[1]
    if info then
      ranges[#ranges + 1] = { info.topline - 1 - OVERSCAN, info.botline - 1 + OVERSCAN }
    end
  end
  return ranges
end

---@param ranges integer[][]
---@param start_row integer
---@param end_row integer
---@return boolean
local function overlaps(ranges, start_row, end_row)
  for _, range in ipairs(ranges) do
    if start_row <= range[2] and end_row >= range[1] then
      return true
    end
  end
  return false
end

---@param node TSNode
---@param type_name string
---@return TSNode[]
local function children(node, type_name)
  local result = {}
  for child in node:iter_children() do
    if child:type() == type_name then
      result[#result + 1] = child
    end
  end
  return result
end

---@param lang string?
---@return string? icon, string? highlight
local function language_icon(lang)
  if not lang or lang == "" then
    return nil, nil
  end
  -- Internal plugin API, so guard it: losing the icon is harmless.
  local ok, icons = pcall(require, "render-markdown.lib.icons")
  if not ok or type(icons.get) ~= "function" then
    return nil, nil
  end
  local ok_get, icon, hl = pcall(icons.get, lang)
  if not ok_get then
    return nil, nil
  end
  return icon, hl
end

---@param text render.md.mark.Line
---@return integer
local function line_width(text)
  local width = 0
  for _, part in ipairs(text) do
    width = width + vim.fn.strdisplaywidth(part[1])
  end
  return width
end

---@param buf integer
---@param node TSNode
---@return render.md.Mark[]
local function box(buf, node)
  local delimiters = children(node, "fenced_code_block_delimiter")
  if #delimiters < 2 then
    -- Unterminated block: nothing sensible to draw.
    return {}
  end
  local top_row, start_col = delimiters[1]:range()
  local bottom_row = delimiters[#delimiters]:range()
  if bottom_row - top_row < 2 then
    -- Empty block, mirrors the builtin renderer which skips these too.
    return {}
  end

  local lang ---@type string?
  local info = children(node, "info_string")[1]
  if info then
    local language = children(info, "language")[1]
    if language then
      lang = vim.treesitter.get_node_text(language, buf)
    end
  end

  local lines = vim.api.nvim_buf_get_lines(buf, top_row + 1, bottom_row, false)
  local max_width = 0
  for _, line in ipairs(lines) do
    max_width = math.max(max_width, vim.fn.strdisplaywidth(line:sub(start_col + 1)))
  end

  local hl = M.highlight
  local label = {} ---@type render.md.mark.Line
  if lang then
    local icon, icon_hl = language_icon(lang)
    label[#label + 1] = { " ", hl }
    if icon then
      label[#label + 1] = { icon .. " ", icon_hl or hl }
    end
    label[#label + 1] = { lang .. " ", icon_hl or hl }
  end

  -- Width between the two vertical bars: a space of padding on each side of
  -- the code, or wider when the language label needs the room.
  local inner = math.max(max_width + 2, line_width(label) + 2)
  local right_col = start_col + 1 + inner

  local marks = {} ---@type render.md.Mark[]

  local top = { { "╭─", hl } } ---@type render.md.mark.Line
  vim.list_extend(top, label)
  top[#top + 1] = { ("─"):rep(inner - 1 - line_width(label)) .. "╮", hl }
  marks[#marks + 1] = {
    conceal = true,
    start_row = top_row,
    start_col = start_col,
    opts = { virt_text = top, virt_text_pos = "overlay" },
  }

  for i, line in ipairs(lines) do
    local row = top_row + i
    -- Lines shorter than the block indent (blank lines inside an indented
    -- block) have no column to anchor at, so pad them out to the indent.
    local col = math.min(start_col, #line)
    local left = (" "):rep(start_col - col) .. "│ "
    marks[#marks + 1] = {
      conceal = false,
      start_row = row,
      start_col = col,
      opts = { priority = 100, virt_text = { { left, hl } }, virt_text_pos = "inline" },
    }
    marks[#marks + 1] = {
      conceal = false,
      start_row = row,
      start_col = col,
      opts = { priority = 100, virt_text = { { "│", hl } }, virt_text_win_col = right_col },
    }
  end

  marks[#marks + 1] = {
    conceal = true,
    start_row = bottom_row,
    start_col = start_col,
    opts = { virt_text = { { "╰" .. ("─"):rep(inner) .. "╯", hl } }, virt_text_pos = "overlay" },
  }

  return marks
end

---@param ctx render.md.handler.Context
---@return render.md.Mark[]
function M.parse(ctx)
  query = query or vim.treesitter.query.parse("markdown", "(fenced_code_block) @code")
  local ranges = visible_ranges(ctx.buf)
  local marks = {} ---@type render.md.Mark[]
  for _, node in query:iter_captures(ctx.root, ctx.buf) do
    local start_row, _, end_row = node:range()
    if not node:has_error() and overlaps(ranges, start_row, end_row) then
      vim.list_extend(marks, box(ctx.buf, node))
    end
  end
  return marks
end

return M
