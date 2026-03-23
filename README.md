# dotfiles

Chezmoi + Nix dotfiles for macOS and Linux.

## Setup

```bash
# One-command bootstrap
curl -fsSL https://raw.githubusercontent.com/urmzd/.dotfiles/main/bootstrap-nix-chezmoi.sh | bash

# Or, if chezmoi is already installed
chezmoi init --apply https://github.com/urmzd/.dotfiles.git
```

## What's included

### Dev environment (Nix flake)

A single unified dev shell with everything:

```bash
nix develop
```

**Languages & runtimes**: Node 22, Deno, Python 3.13, Go, Rust (via rustup), Java 21, Lua 5.4, Haskell (GHC + Cabal), Ruby + Rails, Guile Scheme, Perl

**DevOps & cloud**: Terraform, kubectl, Helm, k9s, AWS CLI, GCloud SDK, Colima, Docker (+ buildx/compose), GoReleaser

**CLI essentials**: git, gh, fzf, ripgrep, jq, yq, just, tmux, direnv, chezmoi, curl, wget, tree, tldr, gnupg, tree-sitter, uv

### Shell & terminal

- Zsh + Oh My Zsh + Powerlevel10k
- Tmux (`Ctrl+a` prefix, vim keys, Catppuccin cyberdream theme)
- Ghostty terminal (cyberdream theme, MonaspiceNe Nerd Font)

### Editor

- Neovim (HEAD) with LSP for all included languages

### AI agent integration

- Claude Code config + custom statusline (`dot_claude/`)
- AGENTS.md for AI agent guidance
- `llms.txt` for LLM-friendly project discovery
- Gemini, Copilot, and Codex configs
- `just status` tracks claude, codex, gemini, and copilot versions

### Agent skills

Portable skills distributed via `npx skills` across AI coding agents:

| Skill | Purpose |
| ----- | ------- |
| ai-workflows | AI-assisted workflow patterns |
| ci-cd | CI/CD pipeline conventions |
| cli-patterns | CLI conventions (JSON piping, stdout/stderr, structured logging) |
| cli-ui | Terminal UI standard (colors, spinners, symbols, layout) |
| development-practices | Coding standards and practices |
| llms-txt | LLM-friendly project summary convention |
| nix-shells | Nix development shell guidance |
| project-scaffolding | Project structure (Justfile, .envrc, Cargo workspace, etc.) |
| readme-standards | README structure and section order |
| release-workflow | End-to-end release pipeline (sr.yaml, CI, multi-platform builds) |
| tools | Canonical tech stack reference by purpose |
| visual-identity | Branding, themes, VHS demos, teasr integration |

### macOS extras (Brewfile)

- Neovim HEAD, cmake, gettext, cocoapods, Android Studio + CLI tools, fonts (MonaspiceNe, Iosevka)
- VHS + ttyd for CLI recordings
- Docker cleanup launchd agent (daily at 3 AM)

## Automation

Chezmoi runs these scripts automatically on `chezmoi apply`:

| Script | Type | Trigger |
| ------ | ---- | ------- |
| `install-packages-v2` | run_once (before) | First apply only |
| `brewfile-install` | run_onchange (before) | Brewfile changes |
| `check-flake` | run_onchange (after) | flake.lock changes |
| `generate-completions` | run_onchange (after) | zshrc or flake.lock changes |
| `install-skills` | run_onchange (after) | Any SKILL.md changes |
| `configure-terminal` | run_once (after) | First apply only |
| `load-docker-cleanup` | run_once (after) | First apply only |

## Day-to-day usage

```bash
chezmoi diff          # preview pending changes
chezmoi apply         # apply dotfile changes

just update           # update Nix flake inputs
just status           # check environment status + AI tool versions
```
