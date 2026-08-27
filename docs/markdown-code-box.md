# Rounded Box Around Markdown Code Blocks

## Original requirement

Fenced code blocks rendered by render-markdown.nvim should not get a special background; a rounded border should be drawn around them instead. Added on 2026-08-27.

## Design decisions

render-markdown.nvim has no bordered-box mode for code blocks: `code.border` only controls a single-character line above and below the block (`thin` / `thick`), and the language label always sits on a filled bar. A full box therefore needs a custom handler (`custom_handlers.markdown`, see `doc/custom-handlers.md` in the plugin), implemented in `lua/markdown_code_box.lua` and registered from `lua/plugins/markdown.lua` with `extends = true` so the builtin markdown handler keeps doing everything else (headings, lists, tables, concealing the ``` fences).

The builtin decorations that would clash with the box are turned off in the same spec: `code.disable_background = true`, `code.border = "none"`, `code.language = false`, `code.sign = false`. The language icon and name move into the top edge of the box, using the plugin's own icon provider (`render-markdown.lib.icons`, an internal API wrapped in `pcall`; if it changes, only the icon disappears).

The box is drawn with extmarks: an `overlay` virtual text on the opening fence line (`╭─ icon lang ───╮`), an `inline` `│ ` prefix plus a `│` at a fixed `virt_text_win_col` on every code line, and an `overlay` on the closing fence line (`╰───╯`). The fixed right column relies on markdown buffers not soft wrapping, which `lua/config/autocmds.lua` already enforces. The width is the widest code line (or the language label if wider) plus one space of padding per side. Blocks indented inside lists are handled by anchoring at the fence's column and padding shorter blank lines.

Top and bottom edges use `conceal = true` so, like the plugin's own language line, they give way to the raw fence when the cursor is on that row; the side bars use `conceal = false` so code text never shifts when the cursor enters a line. The handler only emits marks for blocks that overlap a window's viewport (plus a 10-line overscan matching the plugin), keeping large files cheap; the plugin re-runs handlers on scroll.

The box highlight is `FloatBorder` (`M.highlight` in the module), matching LazyVim's rounded floating windows in whatever colorscheme is active.

## Validation

Rendered a test file (top-level block, block nested in a list item with a blank line, block without a language, empty block) in Neovim 0.12.5 with render-markdown 8.13.1: no background, boxes aligned, nested block indented correctly, `:messages` empty, `:checkhealth render-markdown` reports the configuration as valid.

## Open issues

Lines containing tabs, or other inline virtual text on the same line, can misplace the right edge since the `│ ` prefix shifts the text by two cells and the right bar is at a computed column. Empty code blocks (no body lines) are skipped, as in the builtin renderer.
