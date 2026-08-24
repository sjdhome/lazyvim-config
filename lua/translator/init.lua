-- Inline buffer translation, kiss-translator style: translate lines and show the
-- result below each line as extmark virt_lines, never touching the file itself.
--
-- Backend: the Google translate-pa endpoint (kiss-translator's "Google2"). It is
-- batch-capable, returns results in input order together with the detected source
-- language, and uses a public API key embedded in Google's own web translator (the
-- same one kiss-translator ships), so no personal key is needed. Chosen over the
-- Microsoft Edge endpoint for noticeably better translation quality.
--
-- Design notes:
-- * HTTP goes through `vim.system` + system curl (no plugin dependency); the JSON
--   body is passed via stdin so no argv escaping is needed.
-- * Chunks are sent sequentially: each response schedules the next request, which
--   self-throttles against rate limits and renders progressively.
-- * Cancellation is a per-buffer generation counter: clear/toggle/re-translate
--   bump it, and in-flight responses whose generation is stale become no-ops.
-- * Translation works on a snapshot of the buffer, so edits made while a request
--   is in flight can attach a translation to the wrong row; toggling off and on
--   again fixes it. Extmarks already rendered track edits normally.

local M = {}

M.config = {
  -- Google language codes: zh-CN / zh-TW.
  target = "zh-CN",
  endpoint = "https://translate-pa.googleapis.com/v1/translateHtml",
  -- Public key from Google's web translator widget, same as kiss-translator uses.
  api_key = "AIzaSyATBXajvzQLTDHEQbcpq0Ihe0vWDHmO520",
  -- kiss-translator batches 20 paragraphs / 10000 chars; similar caps here.
  batch_lines = 25,
  batch_chars = 5000,
  timeout_secs = 30,
}

local ns = vim.api.nvim_create_namespace("translator")

-- state[bufnr] = { active = bool, gen = int, errored = bool }
local state = {}

local function set_hl()
  vim.api.nvim_set_hl(0, "KissTranslation", { link = "Comment", default = true })
end

set_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("translator_hl", { clear = true }),
  callback = set_hl,
})

-- Skip lines with nothing worth translating: blanks, single characters, pure
-- punctuation or numbers, separator rows. A line qualifies when it contains an
-- ASCII letter or any non-ASCII byte (covers accented and CJK source text).
local function should_translate(line)
  local trimmed = line:match("^%s*(.-)%s*$")
  if #trimmed < 2 then
    return false
  end
  return trimmed:match("%a") ~= nil or trimmed:match("[\128-\255]") ~= nil
end

-- Greedy chunking under both caps; a single oversized line still gets its own
-- chunk so nothing is dropped.
local function chunk_items(items)
  local chunks, current, chars = {}, {}, 0
  for _, item in ipairs(items) do
    if #current > 0 and (#current >= M.config.batch_lines or chars + #item.text > M.config.batch_chars) then
      table.insert(chunks, current)
      current, chars = {}, 0
    end
    table.insert(current, item)
    chars = chars + #item.text
  end
  if #current > 0 then
    table.insert(chunks, current)
  end
  return chunks
end

local function request(texts, on_done)
  -- translateHtml positional body: [[texts, from, to], "wt_lib"]; "auto" = detect.
  local body = vim.json.encode({ { texts, "auto", M.config.target }, "wt_lib" })
  vim.system({
    "curl",
    "-sS",
    "--fail-with-body",
    "-m",
    tostring(M.config.timeout_secs),
    "-H",
    "Content-Type: application/json+protobuf",
    "-H",
    "X-Goog-API-Key: " .. M.config.api_key,
    "--data-binary",
    "@-",
    M.config.endpoint,
  }, { stdin = body }, vim.schedule_wrap(on_done))
end

-- translateHtml treats input as HTML, so translations can come back with entity
-- escapes (&amp;, &#39;, ...) that must be decoded before display. Mirrors
-- kiss-translator's decodeHTMLTranslationText.
local named_entities = { amp = "&", lt = "<", gt = ">", quot = '"', apos = "'", nbsp = " " }

local function decode_entities(text)
  text = text:gsub("<[bB][rR]%s*/?>%s*", " ")
  text = text:gsub("&#x(%x+);", function(hex)
    return vim.fn.nr2char(tonumber(hex, 16), 1)
  end)
  text = text:gsub("&#(%d+);", function(dec)
    return vim.fn.nr2char(tonumber(dec, 10), 1)
  end)
  text = text:gsub("&(%a+);", function(name)
    return named_entities[name:lower()] or ("&" .. name .. ";")
  end)
  return text
end

-- virt_lines never soft-wrap, so a translation longer than the window would be
-- cut off at the right edge. Wrap it ourselves at character granularity (CJK
-- text has no spaces to break at) into multiple virtual lines.
local function wrap_text(text, width)
  width = math.max(width, 20)
  local lines, current, current_width = {}, {}, 0
  for char in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    local w = vim.fn.strdisplaywidth(char)
    if current_width + w > width and #current > 0 then
      table.insert(lines, table.concat(current))
      current, current_width = {}, 0
    end
    table.insert(current, char)
    current_width = current_width + w
  end
  if #current > 0 then
    table.insert(lines, table.concat(current))
  end
  return lines
end

-- Usable text width of a window showing `buf` (excludes number/sign columns).
-- Wrapping is computed once at render time; a later window resize does not
-- rewrap — toggling the translation off and on again does.
local function text_width(buf)
  local win = vim.fn.win_findbuf(buf)[1] or vim.api.nvim_get_current_win()
  local info = vim.fn.getwininfo(win)[1]
  if info then
    return info.width - info.textoff
  end
  return 80
end

local function render_chunk(buf, chunk, decoded)
  local line_count = vim.api.nvim_buf_line_count(buf)
  local primary_target = M.config.target:match("^[^-]+")
  local width = text_width(buf)
  -- Response shape: [[translated...], [detected_lang...]], both in input order.
  local translations = decoded[1] or {}
  local langs = decoded[2] or {}
  for i, item in ipairs(chunk) do
    local detected = langs[i]
    local translated = type(translations[i]) == "string" and decode_entities(translations[i]) or nil
    -- Drop results whose detected source language is already the target, the
    -- same way kiss-translator discards same-language paragraphs.
    local same_lang = detected == M.config.target or detected == primary_target
    if translated and not same_lang and item.row < line_count then
      local indent = item.text:match("^%s*") or ""
      local virt_lines = {}
      for _, segment in ipairs(wrap_text(translated, width - vim.fn.strdisplaywidth(indent))) do
        table.insert(virt_lines, { { indent .. segment, "KissTranslation" } })
      end
      pcall(vim.api.nvim_buf_set_extmark, buf, ns, item.row, 0, { virt_lines = virt_lines })
    end
  end
end

local function send_chunks(buf, gen, chunks, index)
  local chunk = chunks[index]
  if not chunk then
    return
  end
  local texts = {}
  for _, item in ipairs(chunk) do
    table.insert(texts, item.text)
  end
  request(texts, function(res)
    local st = state[buf]
    if not vim.api.nvim_buf_is_valid(buf) or not st or st.gen ~= gen or st.errored then
      return
    end
    local ok, decoded = false, nil
    if res.code == 0 then
      ok, decoded = pcall(vim.json.decode, res.stdout)
    end
    if not ok or type(decoded) ~= "table" or type(decoded[1]) ~= "table" then
      st.errored = true
      local detail = (res.stderr and res.stderr ~= "" and res.stderr) or res.stdout or "unknown error"
      vim.notify(("Translate failed: %s"):format(vim.trim(detail)), vim.log.levels.ERROR)
      return
    end
    render_chunk(buf, chunk, decoded)
    send_chunks(buf, gen, chunks, index + 1)
  end)
end

--- Translate rows [first, last] (0-indexed, inclusive) of `buf`; nil = whole buffer.
function M.translate(buf, first, last)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  if vim.bo[buf].buftype ~= "" then
    vim.notify("Translate: not a file buffer", vim.log.levels.WARN)
    return
  end
  first = first or 0
  last = last or vim.api.nvim_buf_line_count(buf) - 1

  local lines = vim.api.nvim_buf_get_lines(buf, first, last + 1, false)
  vim.api.nvim_buf_clear_namespace(buf, ns, first, last + 1)

  local items = {}
  for i, line in ipairs(lines) do
    if should_translate(line) then
      table.insert(items, { row = first + i - 1, text = line })
    end
  end
  if #items == 0 then
    vim.notify("Translate: nothing to translate", vim.log.levels.INFO)
    return
  end

  local gen = (state[buf] and state[buf].gen or 0) + 1
  state[buf] = { active = true, gen = gen, errored = false }
  vim.notify(("Translating %d lines..."):format(#items), vim.log.levels.INFO)
  send_chunks(buf, gen, chunk_items(items), 1)
end

function M.clear(buf)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    state[buf] = { active = false, gen = (state[buf] and state[buf].gen or 0) + 1 }
  else
    state[buf] = nil
  end
end

function M.toggle(buf)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  if state[buf] and state[buf].active then
    M.clear(buf)
  else
    M.translate(buf)
  end
end

return M
