---
name: dotfiles
description: Chezmoi dotfiles conventions and patterns. Use when modifying dotfiles, adding new managed files, working with chezmoi templates, or syncing agent skills and subagents through agentspec.
allowed-tools: Read, Grep, Glob, Bash(chezmoi *), Bash(agentspec *)
---

# Chezmoi Dotfiles Conventions

Chezmoi is a general-purpose dotfile manager. This skill documents naming, templating, and agent-resource patterns that apply to any chezmoi-managed dotfiles repo. Substitute paths to your own chezmoi source directory wherever examples reference `~/.local/share/chezmoi`.

## File Naming

- `dot_` prefix maps to `.`. Example: `dot_zshrc` becomes `~/.zshrc`.
- `private_` prefix sets restrictive permissions. Example: `private_dot_ssh/`.
- `.tmpl` suffix indicates a chezmoi template using Go `text/template`.
- `run_once_before_` and `run_once_after_` scripts run once during `chezmoi apply`.
- `run_onchange_` scripts re-run when their content changes.

## Templates

Templates use Go `text/template` with chezmoi data from `~/.config/chezmoi/chezmoi.toml`:

```gotemplate
{{ .chezmoi.os }}
{{ .chezmoi.hostname }}
{{ if eq .chezmoi.os "darwin" }}macOS-specific{{ end }}
```

Use `{{ .chezmoi.os }}` guards for platform-specific blocks.

## Structure

Typical source paths inside a chezmoi repo:

| Source path | Target path | Purpose |
| ----------- | ----------- | ------- |
| `dot_config/` | `~/.config/` | App configs such as Neovim, Ghostty, Tmux, and direnv |
| `dot_zsh/` | `~/.zsh/` | Zsh functions and shell customizations |
| `dot_agents/` | `~/.agents/` | Cross-tool agent skills and subagents |
| `dot_agents/skills/` | `~/.agents/skills/` | Portable agent skills |
| `dot_agents/agents/` | `~/.agents/agents/` | Agent personas and subagents |
| `dot_codex/` | `~/.codex/` | Codex config, profiles, and agents |
| `dot_claude/` | `~/.claude/` | Claude Code config and project-scoped skills |
| `Brewfile.tmpl` | generated Brewfile | Homebrew package source of truth |
| `run_onchange_after_install-*.sh.tmpl` | chezmoi script | Pinned upstream installers |

## Workflow

1. Edit source files in the chezmoi source directory. Run `chezmoi source-path` to find it.
2. Preview changes with `chezmoi diff`.
3. Apply changes with `chezmoi apply`.
4. Track existing home files with `chezmoi add <file>`.

## Agent Resources

- **Agents** live in `dot_agents/agents/*.md` and define how to think.
- **Skills** live in `dot_agents/skills/*/SKILL.md` and define what to do.
- Both deploy to `~/.agents/` and are linked into tools with `agentspec`.
- Edit the chezmoi source, not deployed copies under `~/.agents/`.

## Managing Resources

Use `agentspec` for skills and agents:

```sh
agentspec manage add "$(chezmoi source-path)/dot_agents" --all-tools
agentspec manage validate dot_agents/skills/<name>/SKILL.md
agentspec manage validate dot_agents/agents/<name>.md
agentspec manage verify --accept --name <name>
agentspec sync --fast
agentspec status
```

After editing a local skill or agent:

1. Run `chezmoi apply ~/.agents`.
2. Run `agentspec manage add "$(chezmoi source-path)/dot_agents" --all-tools`.
3. Run `agentspec manage verify --accept --name <name>` for each changed local resource.
4. Run `agentspec sync --fast`.

## Gotchas

- Do not edit deployed copies under `~/.agents/skills/` or `~/.agents/agents/`; chezmoi overwrites them.
- Do not hard-code one user's source path in reusable docs. Use `chezmoi source-path`.
- When a new skill exists in `dot_agents/skills/` but appears unmanaged, adopt it with `agentspec manage add <name> --all-tools`.
- Use `private_` for sensitive configs. Do not manage SSH keys, API keys, or tokens in chezmoi.
