# Mason Ensure Installed De-Duplication

## Original requirement

LazyVim reported `Package is already installing.` while running the `mason.nvim` config. The failure happens when Mason receives a second install request for a package that is already in progress.

## Root cause

The local LazyVim setup enables multiple extras that can append the same package to `mason.nvim`'s `ensure_installed` list. The most likely duplicate found during inspection is `codelldb`, which can be added by both the `clangd` and `rust` LazyVim extras.

LazyVim's Mason config checks whether a package is installed, but it does not check whether that package is already installing before calling `install()`. A duplicated package name can therefore trigger a second install attempt before the first one finishes.

## Fix applied

A local plugin override was added at `lua/plugins/mason.lua`. It filters `opts.ensure_installed` while preserving the first occurrence of every tool name and removing later duplicates.

This keeps all requested tools enabled while preventing repeated install requests from duplicate entries.

## Open issues

This is a defensive workaround around duplicated Mason package requests. It does not change which LazyVim extras request `codelldb` or other tools.

The workaround can be removed if LazyVim or Mason starts handling duplicate `ensure_installed` entries or already-installing packages gracefully upstream.
