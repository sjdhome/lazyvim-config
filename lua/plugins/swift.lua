-- Swift support for SwiftPM packages. LazyVim has no official Swift extra yet.
-- See docs/swift.md for the decisions and the removal condition.

local swiftlint_config_name = ".swiftlint.yml"

---@param dir string
---@return string?
local function find_swiftlint_config(dir)
  return vim.fs.find(swiftlint_config_name, {
    path = dir,
    upward = true,
    stop = vim.fs.dirname(vim.uv.os_homedir()),
  })[1]
end

local function current_swiftlint_config()
  return find_swiftlint_config(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "swift" } },
  },

  -- sourcekit-lsp comes from the Xcode toolchain, not Mason.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        sourcekit = {
          -- The lspconfig default also claims c, cpp, objc and objcpp, which clangd already serves.
          filetypes = { "swift" },
        },
      },
    },
  },

  -- `swift format` from the Xcode toolchain. It reads the nearest .swift-format and uses its
  -- default style when there is none. Format on save is off globally (vim.g.autoformat).
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = { swift = { "swift" } },
    },
  },

  -- SwiftLint from Homebrew, only in projects with a .swiftlint.yml.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.swift = { "swiftlint" }
      opts.linters = opts.linters or {}
      -- Replaces the nvim-lint builtin, which caches the first config it finds for the whole session.
      -- Being a table (not a function) is also what lets LazyVim's `condition` apply.
      opts.linters.swiftlint = {
        condition = function(ctx)
          return find_swiftlint_config(ctx.dirname) ~= nil
        end,
        cmd = "swiftlint",
        stdin = false,
        -- SwiftLint resolves `included`/`excluded` relative to the config file, so no cwd is needed.
        args = { "lint", "--force-exclude", "--use-alternative-excluding", "--config", current_swiftlint_config },
        stream = "stdout",
        ignore_exitcode = true,
        -- Same output format as the nvim-lint builtin.
        parser = require("lint.parser").from_pattern("[^:]+:(%d+):(%d+): (%w+): (.+)", {
          "lnum",
          "col",
          "severity",
          "message",
        }, {
          error = vim.diagnostic.severity.ERROR,
          warning = vim.diagnostic.severity.WARN,
        }, { source = "swiftlint" }),
      }
    end,
  },

  -- lldb-dap from the Xcode toolchain. Not codelldb: its bundled LLDB lacks the Swift-specific extensions.
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      local dap = require("dap")
      if not dap.adapters["lldb-dap"] then
        dap.adapters["lldb-dap"] = {
          type = "executable",
          command = "xcrun",
          args = { "lldb-dap" },
        }
      end
      dap.configurations.swift = {
        {
          type = "lldb-dap",
          request = "launch",
          name = "Launch SwiftPM executable (debug build)",
          -- Run `swift build` first; this only locates the output. The bin path is asked from SwiftPM
          -- because its layout changes between versions (`.build/debug` is now a symlink).
          program = function()
            local bin = vim.trim(vim.fn.system({ "swift", "build", "--show-bin-path" }))
            if vim.v.shell_error ~= 0 then
              vim.notify(
                "swift build --show-bin-path failed in " .. vim.fn.getcwd() .. ":\n" .. bin,
                vim.log.levels.ERROR
              )
              return require("dap").ABORT
            end
            return require("dap.utils").pick_file({ path = bin, executables = true })
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
    end,
  },
}
