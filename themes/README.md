# Themes

One theme colors Ghostty, Neovim, tmux, and the dotfiles' own output (apply scripts and the `dotfiles` CLI). Switch with `dotfiles theme set <name>`; list with `dotfiles theme`.

## Which theme applies

1. The machine's `theme` setting, when it names a theme here or in a pack (a built-in wins a name clash).
2. Otherwise the last pack in `packs` that ships a `theme.toml`.
3. Otherwise `cyberdream`.

Every theme is merged onto [`cyberdream.toml`](cyberdream.toml), so a theme lists only what it changes. An `[nvim]` or `[tmux]` section replaces cyberdream's whole section, since its options belong to one plugin.

## Format

```toml
name = "tokyonight"                      # required; what `dotfiles theme set` takes
description = "Tokyo Night (night)"

ghostty = "TokyoNight Night"             # a Ghostty theme name (`ghostty +list-themes`)

[nvim]
plugin = "folke/tokyonight.nvim"         # lazy.nvim spec
colorscheme = "tokyonight-night"         # :colorscheme argument
module = "tokyonight"                    # require(module).setup(setup), when setup is non-empty
background = "dark"                      # dark | light
lualine = "tokyonight"                   # lualine theme (or "auto")

[nvim.setup]                             # the plugin's setup() options
transparent = true

[tmux]
flavour = "mocha"                        # catppuccin-tmux flavour: mocha, macchiato, frappe, latte, cyberdream

[tmux.colors]                            # optional @thm_* overrides: bg, fg, blue, mauve, surface_0, ...
bg = "#1a1b26"

[ui]                                     # dotfiles output
preset = "default"                       # default | ascii | plain (no color, ASCII markers)
ok = { symbol = "✓", color = "#9ece6a" } # roles: section step ok skip warn fail add remove change dim
```

`color` is a hex color or an ANSI SGR code (`"32"`, `"1;36"`). Per-shell overrides, for example in a pack's `env.zsh`: `DOTFILES_UI_THEME=ascii`, `DOTFILES_UI_OK="[ok]"`, `DOTFILES_UI_COLOR_OK="#9ece6a"`.

## Where it lands

| App | File | Picks up a change |
|---|---|---|
| Ghostty | `~/.config/ghostty/config` (`theme =`) | new window, or reload config |
| Neovim | `~/.config/dotfiles/theme.lua`, read by `init.lua` | restart; lazy.nvim installs a new plugin on start |
| tmux | `~/.config/tmux/theme.conf`, sourced by `tmux.conf` | `prefix + r`, or `tmux kill-server` |
| Apply scripts | `~/.config/dotfiles/theme.sh`, read by `ui.sh` at run time | next apply |
| `dotfiles` CLI | `~/.config/dotfiles/theme.toml` (`[ui]`) | next command |

A pack's `theme.toml` uses the same format; it is checked (valid TOML, a `name`) and read from a validated copy, so a broken file never breaks an apply.
