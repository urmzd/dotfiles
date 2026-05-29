[chezmoi-dotfiles] Dotfiles Management & Agent Skills Registry

## Project Overview

Cross-platform dotfiles managed by [chezmoi](https://www.chezmoi.io/). Targets macOS (primary) with Nix/Homebrew for package management. Also serves as the source-of-truth for a portable agent skills catalog and a small set of subagents (architect, curator, debugger, guardian, ideator, strategist, technical-documentation-architect, writer). The catalog is **cross-project**: once installed via [`agentspec`](https://github.com/urmzd/agentspec), the same skills and subagents are available to any tool (claude-code, codex, gemini, copilot) from any project, not just this repo.

## Build & Apply

```bash
chezmoi apply          # Deploy dotfiles to $HOME
chezmoi diff           # Preview pending changes
chezmoi add <file>     # Track a new file
chezmoi edit <file>    # Edit source, then apply
```

## File Naming Conventions

| Prefix/Suffix | Meaning |
|---|---|
| `dot_` | Maps to `.` (e.g., `dot_zshrc` -> `~/.zshrc`) |
| `private_` | Restrictive file permissions |
| `.tmpl` | Go `text/template` with chezmoi data |
| `run_once_before_` | Run-once setup script (before apply) |
| `run_once_after_` | Run-once setup script (after apply) |
| `run_onchange_` | Re-runs when content hash changes |

This is the canonical reference for chezmoi naming. `CONTRIBUTING.md` and other docs should link here rather than duplicating the table.

## Key Directories

These paths are **chezmoi source paths** inside this repo. After `chezmoi apply` they are deployed to the locations in the "Deployed at" column, which is where they are picked up by tools and other projects.

| Source path | Deployed at | Contents |
|-----------|-------------|----------|
| `dot_agents/skills/` | `~/.agents/skills/` | Portable agent skills (following [Agent Skills Spec](https://agentskills.io/specification)) |
| `dot_agents/agents/` | `~/.agents/agents/` | Subagent definitions (architect, curator, debugger, guardian, ideator, strategist, technical-documentation-architect, writer) |
| `dot_config/` | `~/.config/` | Tool configs (Neovim, Ghostty, Tmux, direnv) |
| `dot_zsh/` | `~/.zsh/` | Zsh functions and customizations |
| `dot_codex/` | `~/.codex/` | Codex CLI config, including the `guardian` profile used by `orchestrate-agents` |

## Discovering Structure

Use `tree` for directory layout and `ripgrep`/`ag` for finding files and patterns. Do not rely on static file listings; discover the current state from the filesystem.

## Using Skills and Subagents in Other Projects

Once `chezmoi apply` has run on the host, skills live at `~/.agents/skills/` and subagents at `~/.agents/agents/`. They are not bound to this repo. From any project:

```bash
agentspec manage list                   # Inspect what's installed
agentspec manage link <name> claude-code # Link a skill/agent to claude-code
agentspec manage link <name> codex       # ...or codex, gemini, etc.
agentspec sync --fast                    # Re-discover and re-link everything
```

The `guardian` subagent and the `orchestrate-agents` skill are designed to work together for multi-agent fleets: `orchestrate-agents` drives the tmux panes, `guardian` supervises them.

## Code Style

- Shell scripts: POSIX-compatible where possible, bash/zsh when needed
- Templates: Use `{{ .chezmoi.os }}` guards for platform-specific blocks

## Testing

```bash
chezmoi diff                    # Dry-run before applying
chezmoi verify                  # Verify source state
```

## Commit Guidelines

- Use conventional commits: `feat:`, `fix:`, `chore:`, `docs:`
- Scope by tool/area: `feat(nvim):`, `fix(zsh):`, `chore(brew):`

## Security

- Never commit secrets, API keys, or tokens
- Use `private_` prefix for sensitive config files
- Use `.tmpl` with chezmoi data or environment variables for secrets
- SSH keys are NOT managed by chezmoi (only `~/.ssh/config`)
