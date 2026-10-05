-- The LazyVim markdown language extra is enabled via lazyvim.json
-- (lazyvim.plugins.extras.lang.markdown). It provides the marksman LSP
-- (disabled below), render-markdown, markdown-preview, and prettier +
-- markdown-toc formatting.
--
-- The extra also wires markdownlint (markdownlint-cli2) into four plugins:
-- conform.nvim (as a formatter), none-ls.nvim and nvim-lint (as
-- diagnostics/linter), and mason.nvim (auto-install). The specs below strip
-- markdownlint back out after the extra's options have been merged, using the
-- function form of `opts` so the filtering runs last.
--
-- The extra's marksman LSP is replaced by markdown-oxide (2026-10-05), which
-- is Obsidian-compatible out of the box. Marksman was a poor fit for Obsidian
-- vaults: it only accepts a workspace marked by `.marksman.toml` or a VCS
-- directory (not `.obsidian`), so without per-vault config it fell back to
-- single-file mode; and its default `[[` completion inserts slugified H1
-- titles, which Obsidian cannot resolve. Its settings can only come from
-- toml files, not from this config. markdown-oxide recognizes `.obsidian`,
-- completes file names, headings and block references (`[[note#^id]]`), and
-- covers marksman's navigation, rename and hover. Lost: marksman's "Table of
-- Contents" code action (the extra's markdown-toc formatter remains).
--
-- markdown-oxide starts in any `.git`, `.obsidian` or `.moxide.toml` root,
-- so it also runs in ordinary repositories. Its unresolved-link diagnostics
-- are kept on for now (on trial); set `unresolved_diagnostics = false` in
-- ~/.config/moxide/settings.toml or a vault's `.moxide.toml` to drop them.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- `enabled = false` also keeps LazyVim from installing it via Mason.
        marksman = { enabled = false },
        markdown_oxide = {
          -- Required by markdown-oxide for file-watch based features such as
          -- the "create unresolved file" code action. Already the Neovim
          -- default on macOS; set explicitly as its setup docs ask.
          capabilities = {
            workspace = {
              didChangeWatchedFiles = { dynamicRegistration = true },
            },
          },
        },
      },
    },
  },

  -- Tweak render-markdown.nvim. Plain tables are merged with
  -- vim.tbl_deep_extend, so only the listed keys are overridden:
  --   * enabled             -> render Markdown by default; the extra's
  --                            `<leader>um` Snacks toggle can turn it off.
  --   * code.*              -> fenced code blocks get no background and no
  --                            builtin border / language line / sign; the
  --                            rounded box is drawn instead by the custom
  --                            handler in lua/markdown_code_box.lua, which
  --                            extends (not replaces) the builtin one.
  --   * code.inline         -> disable the extra background on inline code.
  --   * checkbox.enabled    -> the extra turns it off; turn it back on.
  --   * heading.backgrounds -> empty list disables the per-level heading
  --                            background highlight (icons/foreground stay).
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      enabled = true,
      code = {
        inline = false,
        disable_background = true,
        border = "none",
        language = false,
        sign = false,
      },
      custom_handlers = {
        markdown = {
          extends = true,
          parse = function(ctx)
            return require("markdown_code_box").parse(ctx)
          end,
        },
      },
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
