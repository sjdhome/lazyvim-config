return {
  {
    "akinsho/bufferline.nvim",
    opts = {
      -- The tabpage indicators (1, 2, 3 on the right) get near-invisible
      -- derived colors under gruvbox light hard; pin them to its palette.
      highlights = {
        tab = { fg = "#7c6f64", bg = "#ebdbb2" },
        tab_selected = { fg = "#3c3836", bg = "#f9f5d7", bold = true },
        tab_separator = { fg = "#ebdbb2", bg = "#ebdbb2" },
        tab_separator_selected = { fg = "#ebdbb2", bg = "#f9f5d7" },
        tab_close = { fg = "#7c6f64", bg = "#ebdbb2" },
      },
    },
  },
}
