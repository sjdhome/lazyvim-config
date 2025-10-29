return {
  "neovim/nvim-lspconfig",
  opts = {
    inlay_hints = { enabled = false },
    servers = {
      vtsls = {
        settings = {
          typescript = {
            suggest = {
              completeFunctionCalls = false,
            },
          },
        },
      },
      clangd = {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders=false",
          "--fallback-style=llvm",
        },
      },
      gopls = {
        settings = {
          gopls = {
            usePlaceholders = false,
          },
        },
      },
    },
  },
}
