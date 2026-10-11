-- Gruvbox hard in both modes; 'background' follows the terminal (see
-- lua/config/options.lua). Signs and floats share Normal's bg instead of bg1,
-- so the overrides are per background and swapped before each (re)load.
local overrides = {
  light = {
    SignColumn = { bg = "#f9f5d7" },
    GruvboxRedSign = { fg = "#9d0006", bg = "#f9f5d7" },
    GruvboxGreenSign = { fg = "#79740e", bg = "#f9f5d7" },
    GruvboxYellowSign = { fg = "#b57614", bg = "#f9f5d7" },
    GruvboxBlueSign = { fg = "#076678", bg = "#f9f5d7" },
    GruvboxPurpleSign = { fg = "#8f3f71", bg = "#f9f5d7" },
    GruvboxAquaSign = { fg = "#427b58", bg = "#f9f5d7" },
    GruvboxOrangeSign = { fg = "#af3a03", bg = "#f9f5d7" },
    NormalFloat = { fg = "#3c3836", bg = "#f9f5d7" },
    AvanteSidebarWinSeparator = { fg = "#bdae93", bg = "#f9f5d7" },
    AvanteSidebarWinHorizontalSeparator = { fg = "#bdae93", bg = "#f9f5d7" },
    AvanteConflictIncoming = { bg = "#d3d6a5", fg = "#427b58", bold = true },
    AvanteConflictCurrent = { bg = "#fcd5d1", fg = "#9d0006", bold = true },
    AvanteConflictIncomingLabel = { bg = "#e6e9c1", fg = "#427b58", bold = true },
    AvanteConflictCurrentLabel = { bg = "#fef1ee", fg = "#9d0006", bold = true },
    AvanteToBeDeletedWOStrikethrough = { bg = "#fcd5d1", fg = "#9d0006" },
    AvanteToBeDeleted = { bg = "#fcd5d1", fg = "#9d0006", strikethrough = true },
  },
  dark = {
    SignColumn = { bg = "#1d2021" },
    GruvboxRedSign = { fg = "#fb4934", bg = "#1d2021" },
    GruvboxGreenSign = { fg = "#b8bb26", bg = "#1d2021" },
    GruvboxYellowSign = { fg = "#fabd2f", bg = "#1d2021" },
    GruvboxBlueSign = { fg = "#83a598", bg = "#1d2021" },
    GruvboxPurpleSign = { fg = "#d3869b", bg = "#1d2021" },
    GruvboxAquaSign = { fg = "#8ec07c", bg = "#1d2021" },
    GruvboxOrangeSign = { fg = "#fe8019", bg = "#1d2021" },
    NormalFloat = { fg = "#ebdbb2", bg = "#1d2021" },
  },
}

return {
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      contrast = "hard",
    },
    config = function(_, opts)
      local gruvbox = require("gruvbox")
      gruvbox.setup(opts)

      local function use_overrides()
        gruvbox.config.overrides = overrides[vim.o.background]
      end
      -- The first load may be what makes lazy.nvim load this plugin, in which
      -- case the autocmd below is registered too late to see it.
      use_overrides()
      -- Changing 'background' re-runs :colorscheme, which fires this.
      vim.api.nvim_create_autocmd("ColorSchemePre", {
        pattern = "gruvbox",
        callback = use_overrides,
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
