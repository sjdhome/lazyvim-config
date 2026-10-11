# Following the System Light/Dark Mode

## Requirement

Neovim and Vim (`~/.config/vim`) switch between Gruvbox Light Hard and Gruvbox Dark Hard together with the system mode. Added on 2026-10-11.

## Design

The system mode is owned by darkman, whose hook (`~/.local/share/darkman/desktop-theme.sh`) switches running foot windows with SIGUSR1/SIGUSR2. Both editors follow the terminal rather than the desktop portal, so they match the palette foot actually shows and also work over SSH. The cost is that a terminal that does not switch on its own leaves the editors on its fixed background, and runtime switching needs a terminal with DEC 2031 support.

- Neovim (0.11+) does this natively: it queries the background with OSC 11 at startup and re-queries when the terminal sends a DEC 2031 theme notification. This only works while 'background' is not set explicitly, so `lua/config/options.lua` no longer pins it to `light`.
- Changing 'background' reloads the color scheme. Overrides that hard-code palette colors therefore exist per background: `lua/plugins/colorscheme.lua` swaps gruvbox.nvim's `config.overrides` on `ColorSchemePre`, and `lua/plugins/bufferline.lua` passes `highlights` as a function that bufferline re-evaluates on `ColorScheme`. The Avante overrides only have a light variant; Avante is not installed.
- Vim 9.2 has no DEC 2031 support and ignores the `t_RB` answer once a color scheme has set 'background', so `~/.config/vim/conf.d/theme.vim` handles both: it applies the `t_RB` answer from `TermResponseAll`, enables mode 2031 through `t_TI`/`t_TE`, queries the current mode with `CSI ? 996 n` on every `t_TI` (Vim sends `t_TE` before `:!` and suspension, so a switch made then, e.g. `:!darkman toggle`, would otherwise be missed), and maps the notifications (`CSI ? 997 ; 1 n` / `; 2 n`) to the spare keys `<F36>`/`<F37>`. It also keeps `$BAT_THEME` in sync for fzf previews. Because the terminal answers only after the first screen is drawn, loading the scheme at startup flashed the light variant in dark mode. Deferring the scheme until the answer still showed Vim's default colors for a moment, so `VimEnter` now reads the answers itself with `getchar(0)` (up to 200 ms; keys typed meanwhile are fed back) and loads the scheme before Vim draws the first screen. A pty harness that answers like foot confirmed the dark background is emitted before any buffer text, for both the 996 and the OSC 11 answer. This stays terminal-only and platform-neutral (it works on macOS with any terminal that answers OSC 11); an earlier version that read `darkman get` at startup was dropped on 2026-10-11 because it tied the config to Linux. Neovim does not need this because it waits for the OSC 11 answer before running the user config.

## Validation

Headless Neovim produced the light and dark Hard palettes for Normal, signs, floats and the bufferline tab highlights, including when 'background' was toggled at runtime. In a pty, Vim switched Normal between `#f9f5d7` and `#1d2021` and updated `$BAT_THEME` when `<F36>`/`<F37>` were triggered. On 2026-10-11 the user confirmed in foot that both editors follow `darkman toggle` (including Vim's `:!darkman toggle`) and that Vim starts in dark mode without a flash.
