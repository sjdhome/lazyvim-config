return {
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      contrast = "hard",
      overrides = {
        SignColumn = { bg = "#f9f5d7" }, -- light0_hard
        GruvboxRedSign = { fg = "#9d0006", bg = "#f9f5d7" },
        GruvboxGreenSign = { fg = "#79740e", bg = "#f9f5d7" },
        GruvboxYellowSign = { fg = "#b57614", bg = "#f9f5d7" },
        GruvboxBlueSign = { fg = "#076678", bg = "#f9f5d7" },
        GruvboxPurpleSign = { fg = "#8f3f71", bg = "#f9f5d7" },
        GruvboxAquaSign = { fg = "#427b58", bg = "#f9f5d7" },
        GruvboxOrangeSign = { fg = "#af3a03", bg = "#f9f5d7" },
        NormalFloat = { fg = "#3c3836", bg = "#f9f5d7" },
        AvanteSidebarWinSeparator = { fg = "#bdae93", bg = "#f9f5d7" },  -- light3
        AvanteSidebarWinHorizontalSeparator = { fg = "#bdae93", bg = "#f9f5d7" },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  }
}
