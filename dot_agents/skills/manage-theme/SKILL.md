---
name: manage-theme
description: >
  Switch, create, or debug the color theme of a machine set up by
  urmzd/dotfiles: one theme colors Ghostty, Neovim (colorscheme and lualine),
  tmux (catppuccin flavour and colors), and the dotfiles' own output. Covers
  `dotfiles theme` / `dotfiles theme set`, writing a themes/<name>.toml or a
  pack's theme.toml, and per-shell output overrides (DOTFILES_UI_*). Use when
  the user says "switch to tokyonight", "change my terminal colors", "make a
  theme for our team", "my nvim colors did not change", or "use ASCII output
  in CI". Do NOT use for a project's brand identity, fonts, or demo capture
  (use style-brand), for installing apps or other machine upkeep (use
  manage-machine), or for editing unrelated chezmoi templates (use dotfiles).
allowed-tools: Read, Edit, Write, Bash(dotfiles *), Bash(chezmoi source-path), Bash(chezmoi data *), Bash(ghostty +list-themes*), Bash(git -C *)
---

# Manage the machine theme

One theme drives every app. Never edit the generated files
(`~/.config/dotfiles/theme.*`, `~/.config/tmux/theme.conf`, the `theme =`
line in Ghostty's config): chezmoi overwrites them on the next apply.

## Switch

| Step | Command |
|---|---|
| See themes and the one in effect | `dotfiles theme` (`--format json` for data) |
| Switch, then apply | `dotfiles theme set <name>` |
| Follow the packs again | `dotfiles theme set auto` |
| Confirm | `dotfiles doctor` (the `theme` line) |

After switching, tell the user how each app picks it up: a new Ghostty window,
a Neovim restart (lazy.nvim installs a new colorscheme plugin on start), and
`prefix + r` or `tmux kill-server` for tmux.

Which theme applies: the machine's `theme` setting, else the last pack with a
`theme.toml`, else `cyberdream`.

## Create

- **Personal or shareable:** add `themes/<name>.toml` in the dotfiles repo
  (`chezmoi source-path`); that edits the repo, so the `dotfiles` skill's
  conventions apply. **Team or company:** add `theme.toml` to that pack
  (`dotfiles pack list --format json` gives its folder) and push the pack.
- Start from the closest built-in and change only what differs: every theme
  is merged onto `themes/cyberdream.toml`, but an `[nvim]` or `[tmux]` section
  replaces cyberdream's whole section, so give `[nvim]` its own `plugin`,
  `colorscheme`, `module`, and `setup`.
- Check names before writing them: Ghostty themes from `ghostty +list-themes`;
  the Neovim plugin's README for its colorscheme name, module, and setup keys;
  tmux flavours are catppuccin's (mocha, macchiato, frappe, latte, cyberdream),
  with `[tmux.colors]` for single `@thm_*` overrides.
- Format reference: `themes/README.md` in the repo. Then
  `dotfiles theme set <name>` and `dotfiles doctor`.

```toml
name = "acme"
description = "Acme brand colors"
ghostty = "TokyoNight Night"

[nvim]
plugin = "folke/tokyonight.nvim"
colorscheme = "tokyonight-night"
module = "tokyonight"
lualine = "tokyonight"

[nvim.setup]
style = "night"

[tmux]
flavour = "mocha"

[tmux.colors]
blue = "#ff6600"

[ui]
ok = { color = "#ff6600" }
```

## Output only (one shell, CI, logs)

No theme change needed; set environment variables (in a pack's `env.zsh` to
share them): `DOTFILES_UI_THEME=plain` (no color, ASCII markers) or `ascii`;
`DOTFILES_UI_OK="[ok]"`; `DOTFILES_UI_COLOR_WARN="#e0af68"`. Roles: SECTION,
STEP, OK, SKIP, WARN, FAIL, DIM (the CLI also has ADD, REMOVE, CHANGE).

## Debug

- `dotfiles doctor` says the `theme` setting is unknown: `dotfiles theme`
  lists real names; a pack theme appears only after its pack is fetched.
- A pack theme is ignored: doctor names the parse error in its `theme.toml`.
- Neovim still shows the old colors: restart it; check
  `~/.config/dotfiles/theme.lua` names the new plugin.
- tmux keeps old colors: `tmux kill-server` (catppuccin caches some values).
