local mode_map = {
  n = "normal",
  i = "insert",
  v = "visual",
  V = "visual",
  ["\22"] = "visual",
  R = "replace",
  c = "command",
  s = "visual",
  S = "visual",
}

--- Check if the current mode's lualine_c bg differs from normal mode.
--- Returns mode_fg when it differs (for readability on dark bg), nil otherwise.
local function get_mode_fg_override()
  local mode_name = mode_map[vim.fn.mode():sub(1, 1)] or "normal"
  local hl_group = "lualine_c_" .. mode_name
  local mode_hl = vim.api.nvim_get_hl(0, { name = hl_group, link = false })
  local normal_hl = vim.api.nvim_get_hl(0, { name = "lualine_c_normal", link = false })
  if mode_hl and normal_hl and mode_hl.bg ~= normal_hl.bg then
    return mode_hl.fg, mode_hl.bg, hl_group
  end
  return nil, mode_hl and mode_hl.bg, hl_group
end

return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections.lualine_z = {}

    -- Fix trouble breadcrumb colors not matching lualine_c in non-normal modes.
    --
    -- Root cause: trouble.nvim's fix_statusline() caches highlight groups
    -- with lualine_c_normal's bg/fg, and uses %* (StatusLine reset) between
    -- segments. Both become incorrect when the mode changes.
    local last = opts.sections.lualine_c[#opts.sections.lualine_c]
    if type(last) == "table" and type(last[1]) == "function" and last.cond then
      local orig_fn = last[1]

      last[1] = function()
        local result = orig_fn()
        if not result then
          return result
        end

        local fg_override, bg, hl_group = get_mode_fg_override()

        local hl_ok, highlights = pcall(require, "trouble.config.highlights")
        if hl_ok and highlights._fixed then
          for orig_hl, group in pairs(highlights._fixed) do
            if fg_override then
              vim.api.nvim_set_hl(0, group, { fg = fg_override, bg = bg })
            else
              local orig = vim.api.nvim_get_hl(0, { name = orig_hl, link = false }) or {}
              vim.api.nvim_set_hl(0, group, { fg = orig.fg, bg = bg })
            end
          end
        end

        result = result:gsub("%%%*", "%%#" .. hl_group .. "#")
        return result
      end
    end

    -- Fix lualine_x custom-colored components (noice command, lazy updates, etc.)
    -- whose dark fg colors become unreadable on non-normal mode dark backgrounds.
    for _, component in ipairs(opts.sections.lualine_x) do
      if type(component) == "table" and type(component.color) == "function" then
        local orig_color = component.color
        component.color = function()
          local fg_override = get_mode_fg_override()
          if fg_override then
            return { fg = string.format("#%06x", fg_override) }
          end
          return orig_color()
        end
      end
    end
  end,
}
