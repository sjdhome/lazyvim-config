return {
  {
    "snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = { hidden = true },
          explorer = { hidden = true },
        },
      },
      -- Lower the big-file threshold from the 1.5 MB default to 256 KB.
      --
      -- Why: opening large Markdown files (e.g. an ~8000-line, 316 KB work
      -- log) froze Neovim for ~15 s on a `G` jump. Root cause confirmed by
      -- `vim.treesitter.stop()` removing the freeze entirely: the Treesitter
      -- markdown + injected markdown_inline parse over a deeply nested list
      -- is pathologically slow and blocks the UI thread. snacks.bigfile only
      -- triggers on size > threshold or avg line length > 1000, so this file
      -- (316 KB, ~39 B/line) was never downgraded and ran the full
      -- Treesitter/LSP stack.
      --
      -- With this, files over 256 KB are detected as "bigfile": snacks
      -- stops Treesitter and falls back to Vim syntax, disables completion,
      -- and marksman/LSP no longer attaches. This also fixes the slow cold
      -- start on the same file.
      --
      -- Trade-off: any file > 256 KB (large generated code, big JSON) also
      -- gets the lightweight treatment. It stays fully editable; only heavy
      -- decoration is disabled. Raise this value if a real source file is
      -- being downgraded unexpectedly.
      bigfile = { size = 256 * 1024 },
    },
  },
}
