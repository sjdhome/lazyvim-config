return {
  "folke/noice.nvim",
  opts = {
    routes = {
      -- Hide LSP progress spam from pyright.
      --
      -- Pyright re-analyzes on every keystroke and reports each pass via
      -- $/progress, so noice's bottom-right "mini" view shows an endless
      -- stream of spinner/checkmark messages while typing in Python files.
      -- Progress from other servers (e.g. rust-analyzer indexing) is still
      -- shown.
      {
        filter = {
          event = "lsp",
          kind = "progress",
          cond = function(message)
            local client = vim.tbl_get(message.opts, "progress", "client")
            return client == "pyright" or client == "basedpyright"
          end,
        },
        opts = { skip = true },
      },
      -- TEMPORARY WORKAROUND: hide the harmless "watch.watch: ENOENT"
      -- notification that gopls triggers in go.work workspaces.
      --
      -- gopls (checked against v0.23.0, internal/cache/snapshot.go,
      -- fileWatchingGlobPatterns) always registers a file watcher on
      -- `<go.work dir>/vendor` via workspace/didChangeWatchedFiles, without
      -- checking that the directory exists. Neovim (0.12.5,
      -- runtime/lua/vim/_watch.lua, M.watch) fails to start the fs_event on
      -- the missing path and reports it with
      -- `vim.notify_once("watch.watch: ENOENT: ...", INFO)` instead of
      -- logging it, so every Go workspace without a vendor/ directory shows
      -- this message once per session. Nothing is broken: the other
      -- watchers (per-module directories) still work.
      --
      -- Remove this route when either side is fixed: gopls stops registering
      -- a watcher for a non-existent vendor directory, or Neovim demotes
      -- this ENOENT to a log entry (the source has a TODO for an `nvim_log`
      -- API). See docs/gopls-vendor-watch-notify.md.
      {
        filter = {
          event = "notify",
          find = "^watch%.watch: ENOENT",
        },
        opts = { skip = true },
      },
    },
  },
}
