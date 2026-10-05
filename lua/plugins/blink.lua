-- True when the cursor sits inside an unfinished `[[wiki link` or
-- `[text](path` link target on the current line.
local function in_markdown_link(ctx)
  local before = ctx.line:sub(1, ctx.cursor[2])
  return before:find("%[%[[^%]]*$") ~= nil or before:find("%]%([^%)]*$") ~= nil
end

return {
  "saghen/blink.cmp",
  opts = {
    completion = {
      accept = {
        auto_brackets = {
          enabled = false,
        },
      },
    },
    sources = {
      -- Markdown prose gets no completion popups (buffer words, snippets,
      -- etc.). The only exception is link completion from the markdown LSP
      -- (markdown-oxide, see markdown.lua), shown just while typing a
      -- `[[...` or `](...` link target.
      per_filetype = {
        markdown = { "markdown_links" },
      },
      providers = {
        markdown_links = {
          name = "LSP",
          module = "blink.cmp.sources.lsp",
          should_show_items = in_markdown_link,
        },
      },
    },
  },
}
