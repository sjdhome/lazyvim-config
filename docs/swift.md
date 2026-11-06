# Swift Support

## Original requirement

Add Swift support to LazyVim. Scope agreed on 2026-11-06: SwiftPM packages and standalone `.swift` files. Xcode app projects (`.xcodeproj`, `.xcworkspace`), simulators, and xcodebuild.nvim are excluded for now.

## Why a local spec

LazyVim has no official Swift extra. Upstream PRs #3123 and #3131 were closed while waiting for Mason packages such as `xcode-build-server` and `xcbeautify`. `lua/plugins/swift.lua` follows the shape of a LazyVim lang extra so it can be deleted once an official `lang.swift` extra exists; at that point compare the decisions below before switching.

None of the tools come from Mason. `sourcekit-lsp`, `swift format` and `lldb-dap` ship with the Xcode toolchain, and `swiftlint` is installed with Homebrew. On a machine without Xcode the spec does nothing useful.

## Decisions

- **Treesitter:** the `swift` parser has `generate = true` in nvim-treesitter, so it is generated from the grammar on install. That uses Mason's `tree-sitter` CLI and Node.js.
- **LSP:** `sourcekit` is limited to the `swift` filetype. The lspconfig default also claims `c`, `cpp`, `objc` and `objcpp`, which would attach it next to clangd.
- **Formatting:** conform's `swift` formatter (`swift format`). It uses the nearest `.swift-format`, or swift-format's default style (2-space indentation, 100 columns) when none exists. This is acceptable because `vim.g.autoformat = false` in `lua/config/options.lua`, so formatting only happens on an explicit `<leader>cf`. If autoformat is ever turned on, revisit this, since files in projects without a `.swift-format` would be rewritten on save. Because conform always has a formatter for Swift, LazyVim never falls back to sourcekit-lsp's own formatting.
- **Linting:** SwiftLint runs only when a `.swiftlint.yml` is found upward from the file. The spec replaces nvim-lint's builtin `swiftlint` definition for two reasons. The builtin caches the first config it finds for the whole session, so it would use the wrong config after switching projects. It is also a function, and LazyVim's `condition` only works on table linters. The replacement keeps the builtin's arguments and output parser. SwiftLint resolves `included`/`excluded` relative to the config file, so no working directory is set.
- **Debugging:** an `lldb-dap` adapter run through `xcrun`. codelldb is not used because its bundled LLDB lacks the Swift-specific extensions; its manual says a custom LLDB backend is needed for those. The launch configuration lists executables in `swift build --show-bin-path` because the `.build` layout changes between SwiftPM versions (`.build/debug` is now a symlink to `.build/out/Products/Debug`). It does not build; run `swift build` first, with Neovim's working directory at the package root.

## Validation

Checked on 2026-11-06 with Neovim 0.12.6, LazyVim `99970099`, Swift 6.4.2, swift-format 6.4.4 and SwiftLint 0.65.1, against a `swift package init --type executable` package:

- The Swift parser installed, and Treesitter highlighting was active in `.swift` buffers.
- `sourcekit` attached to `.swift` buffers and reported a type error. It did not attach to a `.c` buffer.
- Formatting used conform's `swift` formatter. Without a config it indented with 2 spaces, and with `.swift-format` setting 4 spaces it indented with 4.
- SwiftLint produced no diagnostics without `.swiftlint.yml` and produced them with one. A file listed in `excluded` was skipped when SwiftLint ran from another directory.
- A breakpoint in `main` was hit through `lldb-dap`.

Completion and go-to-definition were not tested separately; the type error diagnostic shows that sourcekit-lsp's semantic analysis works.

## Open issues

- Linting reads the file from disk, so on `InsertLeave` the diagnostics reflect the last saved state, as with the builtin definition.
- The debug launch shows a picker even when there is only one executable.
- Xcode projects need `xcode-build-server` and a per-project `buildServer.json` before sourcekit-lsp can index them. This is not set up.
