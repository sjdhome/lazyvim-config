return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      local seen = {}
      opts.ensure_installed = vim.tbl_filter(function(tool)
        if seen[tool] then
          return false
        end
        seen[tool] = true
        return true
      end, opts.ensure_installed or {})
    end,
  },
}
