# Tailwind CSS Detection for CSS Buffers

## Original requirement

When a CSS file is opened, detect whether it is a Tailwind CSS file and, if so, stop reporting Tailwind syntax as errors.

## Root cause

`cssls` (`vscode-css-language-server`) only knows standard CSS, so Tailwind directives such as `@apply`, `@theme` and `@tailwind` are reported as `Unknown at rule`. `cssls` settings are per client, and Neovim answers `workspace/configuration` from `client.settings` without looking at `scopeUri`, so lint rules cannot be relaxed for individual buffers through settings alone.

## Fix applied

`lua/plugins/tailwind-css.lua` decides per buffer, when an LSP client would attach (the `root_dir` hook of `vim.lsp.config`):

- A `css` buffer counts as Tailwind if any line starts with `@import "tailwindcss…"` or one of the directives `@tailwind`, `@apply`, `@config`, `@theme`, `@plugin`, `@source`, `@utility`, `@variant`, `@custom-variant`, `@slot`, `@reference`.
- Tailwind buffers get `tailwindcss_css` instead of `cssls`. That server is the `css-language-server` binary shipped in Mason's `tailwindcss-language-server` package (installed by the LazyVim `lang.tailwind` extra). It is the same CSS language service with Tailwind preprocessing, so standard CSS errors such as unknown properties are still reported.
- Other CSS buffers, and SCSS/Less, keep using `cssls`.
- If the Tailwind binary is missing, the buffer falls back to `cssls` so it is never left without a CSS server.

Filetype stays `css`, so Treesitter, Prettier (conform) and mini-hipatterns are unaffected.

Validated on 2026-10-10 with Neovim 0.12.5 and `@tailwindcss/language-server` 0.16.0: a buffer with `@import "tailwindcss"`, `@theme` and `@apply` attached only `tailwindcss_css` and reported just an unknown property; a buffer without Tailwind directives attached `cssls` and still reported `Unknown at rule @foo`.

## Open issues

- Detection runs only when the buffer is first attached. After adding the first Tailwind directive to an existing plain CSS file, run `:e` to re-evaluate.
- The binary path `node_modules/.bin/css-language-server` is an internal layout of the Mason package. If Mason or the package changes it, Tailwind buffers silently fall back to `cssls` and the old errors return.
