return {
  "yetone/avante.nvim",
  config = function(_, opts)
    local function pick(name, key, fallback)
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
      if not ok or not hl or not hl[key] then
        return fallback
      end
      return string.format("#%06x", hl[key])
    end

    local function set_avante_diff_hl()
      -- Prefer current colorscheme's diff colors; fallback to Gruvbox light palette
      local fg_add = pick("DiffAdd", "fg", "#427b58") -- gruvbox faded_aqua
      local fg_del = pick("DiffDelete", "fg", "#9d0006") -- gruvbox faded_red
      local bg_add = pick("DiffAdd", "bg", "#d3d6a5") -- gruvbox light_green_hard
      local bg_del = pick("DiffDelete", "bg", "#fcd5d1") -- light red tint
      local bg_add_dim = pick("CursorLine", "bg", "#e6e9c1")
      local bg_del_dim = pick("NormalFloat", "bg", "#fef1ee")

      vim.api.nvim_set_hl(0, "AvanteConflictIncoming", { bg = bg_add, fg = fg_add, bold = true })
      vim.api.nvim_set_hl(0, "AvanteConflictCurrent", { bg = bg_del, fg = fg_del, bold = true })
      vim.api.nvim_set_hl(0, "AvanteConflictIncomingLabel", { bg = bg_add_dim, fg = fg_add, bold = true })
      vim.api.nvim_set_hl(0, "AvanteConflictCurrentLabel", { bg = bg_del_dim, fg = fg_del, bold = true })
      -- Streaming diff deletions use this group; keep it readable
      vim.api.nvim_set_hl(0, "AvanteToBeDeletedWOStrikethrough", { bg = bg_del, fg = fg_del })
      vim.api.nvim_set_hl(0, "AvanteToBeDeleted", { bg = bg_del, fg = fg_del, strikethrough = true })
    end

    set_avante_diff_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("AvanteGruvboxLightHardHL", { clear = true }),
      callback = set_avante_diff_hl,
    })

    require("avante").setup(opts)
  end,
  opts = {
    instructions_file = "AGENTS.md",
    provider = "openrouter",
    providers = {
      openrouter = {
        __inherited_from = "openai",
        endpoint = "https://openrouter.ai/api/v1",
        api_key_name = "OPENROUTER_API_KEY",
        model = "anthropic/claude-sonnet-4.5",
      },
    },
  },
}
