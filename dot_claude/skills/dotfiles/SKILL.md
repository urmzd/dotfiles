---
name: dotfiles
description: Chezmoi dotfiles conventions and patterns. Use when modifying dotfiles, adding new managed files, or working with chezmoi templates.
allowed-tools: Read Grep Glob Bash
---

# Chezmoi Dotfiles Conventions

Chezmoi is a general-purpose dotfile manager. This skill documents the naming and templating patterns it uses, which apply to **any** chezmoi-managed dotfiles repo, not just one specific user's. Substitute paths to your own chezmoi source dir wherever this skill references `~/.local/share/chezmoi`.

## File Naming

- `dot_` prefix maps to `.` (e.g., `dot_zshrc` -> `~/.zshrc`)
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

Typical layout for a chezmoi source directory (paths shown are inside the **source**, not the deployed `$HOME`):

- `dot_config/` -> `~/.config/` (app configs: nvim, wezterm, etc.)
- `dot_zsh/` -> `~/.zsh/` (zsh modules and plugins)
- `dot_claude/` -> `~/.claude/` (Claude Code settings, skills)
- `dot_agents/` -> `~/.agents/` (agent definitions; personas/subagents)
- `dot_agents/skills/` -> `~/.agents/skills/` (agent skills)
- `Brewfile` -> Homebrew packages (macOS source of truth for CLIs)
- `run_onchange_after_install-*.sh.tmpl` -> Pinned upstream installers (gcloud, aws, cortex, ...)
- `run_once_after_install-ai-clis.sh.tmpl` -> AI tools (Claude/Codex/Gemini/Copilot)

## Agents vs Skills

- **Agents** (`dot_agents/agents/*.md`) define HOW to think. Personas and subagents
- **Skills** (`dot_agents/skills/*/SKILL.md`) define WHAT to do. Capabilities and domain knowledge
- Both are chezmoi-managed (in this setup) and linked into tools (`~/.claude/agents/`, `~/.codex/agents/`, etc.) via [agentspec](https://github.com/urmzd/agentspec)
- Skills live in `~/.agents/skills/` after `chezmoi apply`

## Workflow

1. Edit source files in your chezmoi source dir (run `chezmoi source-path` to print it; the default is `~/.local/share/chezmoi/`)
2. Preview changes: `chezmoi diff`
3. Apply changes: `chezmoi apply`
4. Add existing files: `chezmoi add <file>`

## Managing Resources

Resources (skills, agents) are managed via [agentspec](https://github.com/urmzd/agentspec):

- **`agentspec manage add <source>`** add a skill or agent
- **`agentspec manage list`** list managed resources
- **`agentspec manage link <name> <tool>`** link resource to a tool
- **`agentspec sync --fast`** discover, link, and verify resources
- **`agentspec status`** show managed vs unmanaged inventory

## Portable Usage

Chezmoi is project-agnostic. Other teams or machines can adopt the same conventions:

- Create your own dotfiles repo, use `dot_` / `private_` / `.tmpl` / `run_*` exactly as documented above
- Use this skill as the reference for naming and templating patterns
- Use [agentspec](https://github.com/urmzd/agentspec) to keep `~/.agents/skills/` and `~/.agents/agents/` in sync across machines and tools
- Run `chezmoi source-path` to discover your source dir on any machine; do not hard-code one user's path
