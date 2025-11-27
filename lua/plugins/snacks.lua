return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        layouts = {
          explorer_no_input = {
            layout = {
              backdrop = false,
              width = 40,
              min_width = 40,
              height = 0,
              position = "left",
              border = "none",
              box = "vertical",
              { win = "list", border = "none" },
            },
          },
        },
        sources = {
          explorer = {
            layout = "explorer_no_input",
            hidden = true,
          },
          files = {
            hidden = true,
          },
          grep = {
            hidden = true,
          },
          git_files = {
            hidden = true,
          },
        },
      },
    },
  },
}
