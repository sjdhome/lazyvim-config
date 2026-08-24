-- Name the <leader>t group used by the local translator module
-- (lua/translator, keymaps in lua/config/keymaps.lua), so the which-key popup
-- shows "translate" instead of an unnamed top-level entry. Appending via the
-- function form of opts avoids index-wise clobbering of LazyVim's default
-- which-key spec list.
return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      opts.spec = opts.spec or {}
      table.insert(
        opts.spec,
        { "<leader>t", group = "translate", icon = { icon = "󰗊", color = "cyan" }, mode = { "n", "x" } }
      )
    end,
  },
}
