-- Plain cssls reports Tailwind directives (`@apply`, `@theme`, ...) as
-- unknown at-rules. For CSS buffers that use Tailwind, swap cssls for the
-- Tailwind-aware `css-language-server` bundled with tailwindcss-language-server.
-- See docs/tailwind-css.md.

local root_markers = { "package.json", ".git" }

-- Same directive set the Tailwind CSS server suppresses diagnostics for.
local tailwind_at_rules = {
  "tailwind",
  "apply",
  "config",
  "theme",
  "plugin",
  "source",
  "utility",
  "variant",
  "custom-variant",
  "slot",
  "reference",
}

local function is_tailwind_line(line)
  local rule = line:match("^%s*@([%w-]+)")
  if not rule then
    return false
  end
  if rule == "import" then
    return line:match("^%s*@import%s+[\"']tailwindcss") ~= nil
  end
  return vim.tbl_contains(tailwind_at_rules, rule)
end

local function is_tailwind_buffer(bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    if is_tailwind_line(line) then
      return true
    end
  end
  return false
end

local function tailwind_css_server()
  return LazyVim.get_pkg_path("tailwindcss-language-server", "node_modules/.bin/css-language-server", { warn = false })
end

-- Only hand the buffer over when the replacement server is installed, so a
-- Tailwind file never ends up without any CSS language server.
local function use_tailwind_css(bufnr)
  return is_tailwind_buffer(bufnr) and vim.fn.executable(tailwind_css_server()) == 1
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        cssls = {
          root_dir = function(bufnr, on_dir)
            if vim.bo[bufnr].filetype == "css" and use_tailwind_css(bufnr) then
              return
            end
            on_dir(vim.fs.root(bufnr, root_markers))
          end,
        },
        tailwindcss_css = {
          mason = false,
          cmd = function(dispatchers)
            return vim.lsp.rpc.start({ tailwind_css_server(), "--stdio" }, dispatchers)
          end,
          filetypes = { "css" },
          root_dir = function(bufnr, on_dir)
            if use_tailwind_css(bufnr) then
              on_dir(vim.fs.root(bufnr, root_markers))
            end
          end,
          init_options = { provideFormatter = true },
          settings = {
            css = { validate = true },
          },
        },
      },
    },
  },
}
