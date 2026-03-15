---
name: dotfiles
description: Chezmoi dotfiles conventions and patterns. Use when modifying dotfiles, adding new managed files, or working with chezmoi templates.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
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

Skills are reusable instruction sets stored as `SKILL.md` files in `.claude/skills/<name>/`.

### Adding community skills via npx

Use [npx skills](https://github.com/vercel-labs/skills) to discover and install from the open skills ecosystem:

```bash
npx skills add <owner/repo>                          # Install from a repo (interactive)
npx skills add <owner/repo> --skill <name>            # Install a specific skill
npx skills add <owner/repo> --all                     # Install all skills from a repo
npx skills add <owner/repo> -a claude-code -y         # Non-interactive, target claude-code
npx skills list                                       # List installed skills
npx skills find                                       # Search for skills
npx skills remove                                     # Remove a skill
npx skills update                                     # Update installed skills
```

### Creating skills manually

1. Create a directory: `mkdir -p ~/.claude/skills/<skill-name>/`
2. Add a `SKILL.md` with YAML frontmatter (`name`, `description`) and markdown instructions
3. Skills in `~/.claude/skills/` are personal (all projects); `.claude/skills/` are project-scoped
