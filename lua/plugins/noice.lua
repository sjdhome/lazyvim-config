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
    },
  },
}
