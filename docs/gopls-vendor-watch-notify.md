# gopls Vendor Directory Watch Notification Filter

## Original requirement

While browsing Go projects, Neovim showed this notification once per session:

```
watch.watch: ENOENT: no such file or directory
```

It appeared alongside a `golangci-lint` failure, which turned out to be a separate problem (a Mason-installed `golangci-lint` built with an older Go than the local toolchain) and is not covered here. The user asked for the `watch.watch` message to be hidden temporarily, with the reasoning and the removal condition written down.

## Root cause

The message is produced by Neovim's built-in LSP file watcher, not by user config.

- gopls registers `workspace/didChangeWatchedFiles` watchers for the workspace. In `go.work` mode it always adds a watcher whose `baseUri` is `<go.work directory>/vendor`, without checking that the directory exists. Verified in gopls v0.23.0, `internal/cache/snapshot.go`, function `fileWatchingGlobPatterns` (the `GoWorkView` branch builds `workVendorDir` and adds it unconditionally).
- Neovim 0.12.5 handles each registration in `runtime/lua/vim/_watch.lua`, `M.watch`. When `uv.new_fs_event():start(path)` fails with `ENOENT`, it calls `vim.notify_once("watch.watch: <err>", vim.log.levels.INFO)` and drops that watcher. The source comment says this is a placeholder until an `nvim_log` API exists.

Reproduced headlessly on `~/Projects/Phi/janus` (a `go.work` workspace with `core`, `mcp-servers`, `openapi-mcp` and no `vendor/`). The LSP trace log showed four `baseUri` registrations with pattern `**/*.{mod,work}`; the three module directories exist and `.../janus/vendor` does not. The other three watchers are unaffected, so nothing functional is lost. The same will happen in any `go.work` workspace that is not vendored.

## Fix applied

A noice.nvim route was added in `lua/plugins/noice.lua`:

```lua
{
  filter = { event = "notify", find = "^watch%.watch: ENOENT" },
  opts = { skip = true },
}
```

noice overrides `vim.notify` by default (LazyVim keeps `notify.enabled = true`), so the `notify_once` call goes through noice's routing and the message is dropped before it reaches the notifier. The match is anchored to the `watch.watch: ENOENT` prefix so other watcher errors (for example `watch.watchdirs` or non-ENOENT failures) are still shown.

The filter is display-only. Neovim still skips the failed watcher exactly as before; the route only hides the notification.

Rejected alternatives:

- Disabling `workspace/didChangeWatchedFiles` for gopls: would stop gopls from noticing `go.mod` / `go.work` edits made outside the buffer.
- Patching `vim._watch`: modifies runtime files and does not survive Neovim upgrades.

## Open issues

This is a temporary workaround. Remove the route from `lua/plugins/noice.lua` (and this document) when either of these is true:

- gopls no longer registers a watcher for a non-existent `vendor` directory. Check `fileWatchingGlobPatterns` in `internal/cache/snapshot.go` of the installed gopls, or simply remove the route, open a non-vendored `go.work` project, and see whether the message returns.
- Neovim stops surfacing this `ENOENT` through `vim.notify_once` (for example once `vim/_watch.lua` logs it instead). Same check: remove the route and see whether the message returns.

Cost of keeping it: negligible. The only risk is that a genuine `watch.watch: ENOENT` for a directory that should exist would also be hidden; that case has not been observed and would still be visible in the LSP log at trace level.
