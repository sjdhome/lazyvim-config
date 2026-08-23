return {
  {
    "ojroques/vim-oscyank",
    branch = "main",
    keys = {
      { "\\c", "<Plug>OSCYankOperator", mode = "n", desc = "OSC yank operator" },
      { "\\cc", "\\c_", mode = "n", remap = true, desc = "OSC yank line" },
      { "\\c", "<Plug>OSCYankVisual", mode = "x", desc = "OSC yank selection" },
    },
  },
}
