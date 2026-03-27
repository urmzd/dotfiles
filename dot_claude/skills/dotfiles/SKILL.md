---
name: dotfiles
description: Chezmoi dotfiles conventions and patterns. Use when modifying dotfiles, adding new managed files, or working with chezmoi templates.
allowed-tools: Read Grep Glob Bash
---

# Chezmoi Dotfiles Conventions

## File Naming

- `dot_` prefix maps to `.` (e.g., `dot_zshrc` → `~/.zshrc`)
- `private_` prefix sets restrictive permissions (e.g., `private_dot_ssh/`)
- `.tmpl` suffix indicates a chezmoi template using Go text/template syntax
- `run_once_before_` / `run_once_after_` scripts run once during `chezmoi apply`
- `run_onchange_` scripts re-run when their content changes

## Templates

Templates use Go `text/template` with chezmoi data from `~/.config/chezmoi/chezmoi.toml`:

```
{{ .chezmoi.os }}
{{ .chezmoi.hostname }}
{{ if eq .chezmoi.os "darwin" }}macOS-specific{{ end }}
```

## Structure

- `dot_config/` → `~/.config/` (app configs: nvim, wezterm, etc.)
- `dot_zsh/` → `~/.zsh/` (zsh modules and plugins)
- `dot_claude/` → `~/.claude/` (Claude Code settings, skills, agents)
- `Brewfile` → Homebrew dependencies
- `flake.nix` → Nix dependencies

## Workflow

1. Edit source files in `~/.local/share/chezmoi/`
2. Preview changes: `chezmoi diff`
3. Apply changes: `chezmoi apply`
4. Add existing files: `chezmoi add <file>`

## Managing Skills

Skills are managed via `npx skills` (the [agentskills.io](https://agentskills.io) CLI):

- `npx skills add <repo> -g` — install a skill globally
- `npx skills list -g` — list globally installed skills
- `npx skills update` — update all skills
- `npx skills find` — search for skills interactively
