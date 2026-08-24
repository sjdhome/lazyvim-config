# Inline Buffer Translation

## Original requirement

Provide a kiss-translator-like experience inside Neovim: press a keybinding to translate the current buffer (or a visual selection) and show each line's translation directly below it, without modifying the file. Added on 2026-08-24.

## Design decisions

The logic lives in a local module at `lua/translator/init.lua` rather than a standalone plugin or a lazy.nvim `dir =` spec. The config directory is already on the runtimepath, so the module is `require`-able with no registration, and the keymaps in `lua/config/keymaps.lua` require it lazily, which gives the same lazy loading a `keys` spec would.

The backend is the Google translate-pa endpoint (`POST https://translate-pa.googleapis.com/v1/translateHtml`), kiss-translator's "Google2" backend, using the public API key embedded in Google's own web translator widget. It is batch-capable (positional body `[[texts, "auto", "zh-CN"], "wt_lib"]`, response `[[translations], [detected_langs]]`) and reports the detected source language per item. The endpoint treats input as HTML, so translations are decoded for HTML entities before display. The module originally used the Microsoft Edge free endpoint (kiss-translator's default); it was switched to Google on 2026-08-24 for better translation quality.

HTTP goes through `vim.system` + system curl with the JSON body passed via stdin, so there is no plugin dependency and no argv escaping concern. Requests are chunked (25 lines / 5000 chars) and sent sequentially for self-throttling and progressive rendering.

Translations render as extmark `virt_lines` under the `KissTranslation` highlight group (linked to `Comment` by default, re-applied on `ColorScheme`). Because virtual lines never soft-wrap, translations longer than the window are wrapped manually at character granularity (CJK text has no spaces to break at) to the window's usable text width and rendered as multiple virtual lines. Lines with nothing to translate (blanks, pure punctuation or numbers) are skipped, and results whose detected source language already equals the target are discarded, mirroring kiss-translator's behavior.

The `<leader>t` which-key group is named "translate" via `lua/plugins/which-key.lua`, using the function form of `opts` to append to LazyVim's default spec list without clobbering it.

Cancellation uses a per-buffer generation counter: clear, toggle-off, or re-translate bumps it, and stale in-flight responses become no-ops.

## Usage

- `<leader>tt` (normal mode): toggle translation of the whole buffer.
- `<leader>tt` (visual mode): translate the selected lines.
- `:Translate` / `:TranslateClear`: command equivalents.

## Open issues

Translation works on a snapshot of the buffer, so edits made while requests are in flight can attach a translation to the wrong row; toggling off and on again fixes it. Extmarks already rendered track later edits normally.

Wrapping is computed once at render time against the window width; resizing the window afterwards does not rewrap existing translations. Toggling off and on again does.

The endpoint relies on a public but unofficial API key; Google may rate-limit, rotate, or retire it. Fallback options are the Microsoft Edge free endpoint (`POST https://edge.microsoft.com/translate/translatetext?from=&to=zh-Hans&isEnterpriseClient=false`, JSON string array in/out, previously used here — see git history), the Google `translate_a/single` endpoint (single text per request), or a keyed API; only `M.config`, `request`, and the response parsing in `lua/translator/init.lua` would need to change.
