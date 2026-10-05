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
| `dot_codex/` | `~/.codex/` | Codex CLI config: workspace-write "Auto" base + `writer`/`reviewer`/`plan`/`guardian` profile overlays and matching `/agent` subagents in `dot_codex/agents/` |
| `dot_gemini/` | `~/.gemini/` | Legacy Gemini CLI settings, kept as Antigravity CLI (agy) first-run migration seed; agy config lives in `~/.gemini/antigravity-cli/` |
| `dot_config/opencode/` | `~/.config/opencode/` | OpenCode instructions; native install, update, and status managed by dotfiles; portable agents rendered by agentspec |
| `dot_copilot/` | `~/.copilot/` | GitHub Copilot CLI config (`settings.json`: model, effort, theme) |
| `catalog.toml` | (not deployed) | Optional packages. Selected per machine at `[data].packages`; rendered by `Brewfile.tmpl`; managed with the `dotfiles` CLI in `cli/` |
| `work-pack/` | (not deployed) | Starter template for a company work pack repo (cloned to `~/.config/work/` on work machines) |
| `cli/` | (not deployed) | Rust source for the `dotfiles` CLI; built and attached to every release by `release.yml` |
| (not tracked) | `~/.config/work/` or a local folder | Optional work pack: `work_pack` is empty, a git URL (cloned by `run_after_sync-work-pack.sh.tmpl`, never fatal), or a local path; `.chezmoitemplates/work-pack-dir` resolves the folder for every hook. Never add its files to this repo |

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

- Shell scripts: POSIX-compatible where possible, bash/zsh when needed. **bash 3.2 is the floor**: `#!/usr/bin/env bash` finds macOS's `/bin/bash` 3.2 on a fresh Mac. Every `run_` and `modify_` template starts with `{{ includeTemplate "bash-modern.sh" . }}` right after the shebang, which re-runs the script under Homebrew's bash 5 when present, but scripts must still work on 3.2. No associative arrays, `mapfile`, `${x,,}`, `|&`, `&>>`, `[[ -v`, or heredocs inside `$(...)` (3.2 misparses them; use `IFS= read -r -d '' var <<'EOF' || true`). Guard array expansions under `set -u` (`${a[@]+"${a[@]}"}`; 3.2 aborts on empty arrays). Never pipe a download into a shell (`curl | sh`, `sh -c "$(curl ...)"`): a failed download runs an empty script that "succeeds"; use `fetch_and_run <url> <shell>` from `ui.sh`. `.github/scripts/lint-shell.sh` enforces all of this in CI.
- Templates: Use `{{ .chezmoi.os }}` guards for platform-specific blocks
- Script output: every `run_` script includes `{{ includeTemplate "ui.sh" . }}` and prints only through its `ui_*` helpers (one `ui_section`, quiet when nothing changed, a `ui_hint` with the next step under every warning or failure). No raw `echo` status lines or emoji.

## Testing

```bash
.github/scripts/check.sh        # Render personal + work machines, bash -n every run_ script (same as CI)
chezmoi diff --use-builtin-diff # Dry-run before applying (diff.command is nvim; it hangs headless)
chezmoi verify                  # Verify source state
```

The `dotfiles` CLI is a Rust crate in `cli/` (see `cli/README.md`):

```bash
cd cli && cargo fmt --all -- --check && cargo clippy --all-targets -- -D warnings && cargo test
```

CI (`.github/workflows/ci.yml`) runs `check.sh` on macOS and Linux plus the `cli/` checks for every PR; `release.yml` runs CI again, then `sr` tags, bumps `cli/Cargo.toml`, writes `CHANGELOG.md`, and a matrix attaches `dotfiles-<target>` binaries with `.sha256` files to the release.

## Commit Guidelines

- Use conventional commits: `feat:`, `fix:`, `chore:`, `docs:`
- Scope by tool/area: `feat(nvim):`, `fix(zsh):`, `chore(brew):`

## Security

- Never commit secrets, API keys, or tokens
- Use `private_` prefix for sensitive config files
- Use `.tmpl` with chezmoi data or environment variables for secrets
- SSH keys are NOT managed by chezmoi (only `~/.ssh/config`)
