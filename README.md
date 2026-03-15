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

### Dev environments (Nix flakes)

```bash
nix develop .#<shell>
```

| Shell    | What's in it                                          |
| -------- | ----------------------------------------------------- |
| default  | JS/TS, Go, Rust, Java, Lua, DevOps, Cloud, AI        |
| node     | Node 22, Deno, npm, yarn, pnpm, tsc                  |
| python   | Python 3.13                                           |
| rust     | rustc, cargo, rustfmt, clippy, cargo-watch/edit/outdated |
| go       | go, golangci-lint, gotools, go-migrate, air           |
| devops   | terraform, kubectl, helm, k9s, awscli, colima, docker, docker-buildx/compose, gcloud |
| haskell  | ghc, cabal-install                                    |
| ruby     | ruby, bundler, rails                                  |
| scheme   | guile                                                 |
| perl     | perl                                                  |
| lua      | lua 5.4, luarocks, stylua, luacheck, ninja            |
| full     | default + Python                                      |

### Shell & terminal

- Zsh + Oh My Zsh + Powerlevel10k
- Tmux (`Ctrl+a` prefix, vim keys, Catppuccin cyberdream theme)
- Ghostty terminal

### Editor

- Neovim (HEAD) with LSP for all included languages

### macOS extras (Brewfile)

- Neovim HEAD, cmake, gettext, cocoapods, Android Studio + CLI tools, fonts (MonaspiceNe, Iosevka)
- VHS + ttyd for CLI recordings
- Docker cleanup launchd agent (daily at 3 AM)

### Agent skills

Portable skills distributed via `npx skills` across AI coding agents:

| Skill | Purpose |
| ----- | ------- |
| ai-workflows | AI-assisted workflow patterns |
| ci-cd | CI/CD pipeline conventions |
| development-practices | Coding standards and practices |
| nix-shells | Nix development shell guidance |
| tools | Tooling conventions |
| visual-identity | Branding and visual standards |

### Common CLI (in every Nix shell)

git, gh, fzf, ripgrep, jq, yq, just, tmux, direnv, chezmoi, curl, wget, tree, tldr, gnupg, tree-sitter

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
just status           # check environment status
```
