-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Inline translation (lua/translator): kiss-translator-style virt_lines below
-- each line. The callbacks require the module lazily, so it is only loaded on
-- first use — same effect as a lazy.nvim `keys` spec.
vim.keymap.set("n", "<leader>tt", function()
  require("translator").toggle(0)
end, { desc = "Toggle buffer translation" })

vim.keymap.set("x", "<leader>tt", function()
  -- Read the range via line("v")/line(".") while still in visual mode; the
  -- '< and '> marks are only updated after leaving it.
  local first, last = vim.fn.line("v"), vim.fn.line(".")
  if first > last then
    first, last = last, first
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  require("translator").translate(0, first - 1, last - 1)
end, { desc = "Translate selection" })

vim.api.nvim_create_user_command("Translate", function()
  require("translator").translate(0)
end, { desc = "Translate current buffer" })

vim.api.nvim_create_user_command("TranslateClear", function()
  require("translator").clear(0)
end, { desc = "Clear buffer translation" })
