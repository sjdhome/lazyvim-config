-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.autoformat = false

-- 'background' is left unset so Nvim follows the terminal: it queries OSC 11
-- at startup and re-queries on DEC 2031 theme notifications (foot sends them
-- when darkman switches it). See docs/system-theme.md.

-- Render spaces as faint middle dots, matching ~/.config/vim/conf.d/custom.vim
-- (listchars=tab:\ \ ,space:·,eol:\ ). LazyVim already sets `list = true`;
-- the dots stay subtle because gruvbox colors the Whitespace group with bg2.
vim.opt.listchars = { tab = "  ", space = "·", eol = " " }

-- Absolute line numbers only (LazyVim enables relativenumber by default).
vim.opt.relativenumber = false

-- Use finer horizontal mouse-wheel steps than Neovim's 6-column default.
vim.opt.mousescroll = "ver:3,hor:3"

local osc52 = require("vim.ui.clipboard.osc52")
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = osc52.copy("+"),
    ["*"] = osc52.copy("*"),
  },
  paste = {
    ["+"] = osc52.paste("+"),
    ["*"] = osc52.paste("*"),
  },
}
vim.opt.clipboard = ""
