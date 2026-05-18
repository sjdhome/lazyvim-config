-- The LazyVim markdown language extra is enabled via lazyvim.json
-- (lazyvim.plugins.extras.lang.markdown). It provides the marksman LSP,
-- render-markdown, markdown-preview, and prettier + markdown-toc formatting.
--
-- The extra also wires markdownlint (markdownlint-cli2) into four plugins:
-- conform.nvim (as a formatter), none-ls.nvim and nvim-lint (as
-- diagnostics/linter), and mason.nvim (auto-install). The specs below strip
-- markdownlint back out after the extra's options have been merged, using the
-- function form of `opts` so the filtering runs last.
return {
  -- Tweak render-markdown.nvim. Plain tables are merged with
  -- vim.tbl_deep_extend, so only the listed keys are overridden:
  --   * enabled             -> start with rendering off; the extra's
  --                            `<leader>um` Snacks toggle still turns it on.
  --   * checkbox.enabled    -> the extra turns it off; turn it back on.
  --   * heading.backgrounds -> empty list disables the per-level heading
  --                            background highlight (icons/foreground stay).
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      enabled = false,
      checkbox = { enabled = true },
      heading = { backgrounds = {} },
    },
  },

  -- Drop markdownlint-cli2 from the conform.nvim formatter chain.
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs({ "markdown", "markdown.mdx" }) do
        if opts.formatters_by_ft[ft] then
          opts.formatters_by_ft[ft] = vim.tbl_filter(function(formatter)
            return formatter ~= "markdownlint-cli2"
          end, opts.formatters_by_ft[ft])
        end
      end
    end,
  },

  -- Remove the markdownlint diagnostics source from none-ls.
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      opts.sources = vim.tbl_filter(function(source)
        return not (source.name and tostring(source.name):find("markdownlint"))
      end, opts.sources or {})
    end,
  },

  -- Remove the markdownlint-cli2 linter from nvim-lint.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      if opts.linters_by_ft and opts.linters_by_ft.markdown then
        opts.linters_by_ft.markdown = vim.tbl_filter(function(linter)
          return linter ~= "markdownlint-cli2"
        end, opts.linters_by_ft.markdown)
      end
    end,
  },

  -- Don't auto-install markdownlint-cli2 via Mason.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return tool ~= "markdownlint-cli2"
      end, opts.ensure_installed or {})
    end,
  },
}
