return {
  "folke/sidekick.nvim",
  opts = {
    -- Disable Copilot Next Edit Suggestions; keep the CLI integration.
    -- With this set, the LazyVim sidekick extra also skips registering the
    -- copilot language server entirely.
    nes = { enabled = false },
    -- Also hide the Copilot status icon that the LazyVim sidekick extra
    -- adds to lualine (it shows whenever sidekick.status.get() is non-nil).
    copilot = { status = { enabled = false } },
  },
}
