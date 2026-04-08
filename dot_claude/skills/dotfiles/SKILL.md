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
- `dot_claude/` → `~/.claude/` (Claude Code settings, skills)
- `dot_agents/` → `~/.agents/` (agent definitions; personas/subagents)
- `skills/` → skills installed to `~/.agents/skills/` via agentspec
- `Brewfile` → Homebrew dependencies
- `flake.nix` → Nix dependencies

## Agents vs Skills

- **Agents** (`dot_agents/agents/*.md`) define HOW to think. Personas and subagents
- **Skills** (`skills/*/SKILL.md`) define WHAT to do. Capabilities and domain knowledge
- Agents are chezmoi-managed; agentspec links them to tools (`~/.claude/agents/`, etc.)
- Skills live in `~/.agents/skills/` and are managed by agentspec

## Workflow

1. Edit source files in `~/.local/share/chezmoi/`
2. Preview changes: `chezmoi diff`
3. Apply changes: `chezmoi apply`
4. Add existing files: `chezmoi add <file>`

## Managing Resources

Resources (skills, agents) are managed via [agentspec](https://github.com/anthropics/agentspec):

- **`agentspec manage add <source>`** add a skill or agent
- **`agentspec manage list`** list managed resources
- **`agentspec manage link <name> <tool>`** link resource to a tool
- **`agentspec sync --fast`** discover, link, and verify resources
- **`agentspec status`** show managed vs unmanaged inventory
