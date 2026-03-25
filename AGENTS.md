[chezmoi-dotfiles] Dotfiles Management

## Project Overview

Cross-platform dotfiles managed by [chezmoi](https://www.chezmoi.io/). Targets macOS (primary) with Nix/Homebrew for package management.

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
| `dot_` | Maps to `.` (e.g., `dot_zshrc` → `~/.zshrc`) |
| `private_` | Restrictive file permissions |
| `.tmpl` | Go `text/template` with chezmoi data |
| `run_once_before_` | Run-once setup script (before apply) |
| `run_once_after_` | Run-once setup script (after apply) |
| `run_onchange_` | Re-runs when content hash changes |

## Discovering Structure

Use `tree` for directory layout and `ripgrep`/`ag` for finding files and patterns. Do not rely on static file listings — discover the current state from the filesystem.

## Code Style

- Shell scripts: POSIX-compatible where possible, bash/zsh when needed
- Templates: Use `{{ .chezmoi.os }}` guards for platform-specific blocks
- Prefer `justfile` targets over raw shell scripts for common tasks

## Testing

```bash
chezmoi diff                    # Dry-run before applying
chezmoi verify                  # Verify source state
just check                      # Run project checks via justfile
```

## Commit Guidelines

- Use conventional commits: `feat:`, `fix:`, `chore:`, `docs:`
- Scope by tool/area: `feat(nvim):`, `fix(zsh):`, `chore(brew):`

## Security

- Never commit secrets, API keys, or tokens
- Use `private_` prefix for sensitive config files
- Use `.tmpl` with chezmoi data or environment variables for secrets
- SSH keys are NOT managed by chezmoi (only `~/.ssh/config`)
