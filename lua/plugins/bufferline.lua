return {
  {
    "akinsho/bufferline.nvim",
    opts = {
      -- The tabpage indicators (1, 2, 3 on the right) get near-invisible
      -- derived colors under gruvbox hard; pin them to its palette. A function
      -- so bufferline re-evaluates it on ColorScheme, after 'background' flips.
      highlights = function()
        local c = vim.o.background == "dark"
            and { fg4 = "#a89984", fg1 = "#ebdbb2", bg1 = "#3c3836", bg0 = "#1d2021" }
          or { fg4 = "#7c6f64", fg1 = "#3c3836", bg1 = "#ebdbb2", bg0 = "#f9f5d7" }
        return {
          tab = { fg = c.fg4, bg = c.bg1 },
          tab_selected = { fg = c.fg1, bg = c.bg0, bold = true },
          tab_separator = { fg = c.bg1, bg = c.bg1 },
          tab_separator_selected = { fg = c.bg1, bg = c.bg0 },
          tab_close = { fg = c.fg4, bg = c.bg1 },
        }
      end,
    },
  },
}
