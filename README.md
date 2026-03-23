<p align="center">
  <h1 align="center">dotfiles</h1>
  <p align="center">
    Cross-platform dev environment powered by Chezmoi + Nix — one command to a fully configured machine.
    <br /><br />
    <a href="#quick-start">Quick Start</a>
    &middot;
    <a href="https://github.com/urmzd/dotfiles/issues">Report Bug</a>
    &middot;
    <a href="#agent-skill">Agent Skill</a>
  </p>
</p>

## Philosophy

This repo treats the development environment as a product. Every tool, config, and automation exists to remove friction between thinking and shipping.

- **One shell, everything included** — A single `nix develop` gives you every language, CLI tool, and cloud SDK. No version managers, no manual installs.
- **Declarative over imperative** — Nix pins exact versions. Chezmoi templates handle platform differences. The environment is reproducible, not documented.
- **Automate the boring parts** — Chezmoi scripts run on apply: packages install themselves, completions regenerate, skills stay in sync. You never run setup steps manually twice.
- **AI-native workflow** — Claude Code, Gemini, Codex, and Copilot are first-class citizens. Agent skills encode project conventions as portable instructions so AI tools understand how you work.
- **Skills replace docs** — Instead of a `docs/` folder, knowledge lives in `SKILL.md` files that both humans and AI agents can consume. README is for humans. AGENTS.md is for AI. Skills bridge both.

## Features

- Unified Nix dev shell with 15+ languages and 40+ tools
- Zsh + Oh My Zsh + Powerlevel10k with auto-completions for all Nix packages
- Tmux (`Ctrl+a` prefix, vim keys, Catppuccin cyberdream theme)
- Ghostty terminal (cyberdream theme, MonaspiceNe Nerd Font)
- Neovim (HEAD) with LSP for all included languages
- AI agent integration (Claude Code, Gemini, Codex, Copilot) with auto-install
- 13 portable agent skills distributed via `npx skills`
- Chezmoi automation scripts that trigger on apply
- macOS extras via Homebrew (fonts, Android tooling, VHS for CLI recordings)
- Docker cleanup launchd agent (daily at 3 AM)

## Quick Start

```bash
# One-command bootstrap (installs Nix + Chezmoi, then applies everything)
curl -fsSL https://raw.githubusercontent.com/urmzd/.dotfiles/main/bootstrap-nix-chezmoi.sh | bash

# Or, if chezmoi is already installed
chezmoi init --apply https://github.com/urmzd/.dotfiles.git
```

After bootstrap completes, open a new terminal. The Nix dev shell activates automatically via direnv.

## Usage

### Day-to-day

```bash
chezmoi diff          # Preview pending dotfile changes
chezmoi apply         # Apply dotfile changes to $HOME
chezmoi add <file>    # Start tracking a new file
chezmoi edit <file>   # Edit source, then apply
```

### Nix environment

```bash
nix develop           # Enter the dev shell (or use direnv)
just update           # Update all Nix flake inputs and rebuild
just status           # Check flake age + AI tool versions
```

### What's in the shell

**Languages & runtimes**: Node 22, Deno, Python 3.13, Go, Rust (via rustup), Java 21, Lua 5.4, Haskell (GHC + Cabal), Ruby + Rails, Guile Scheme, Perl

**DevOps & cloud**: Terraform, kubectl, Helm, k9s, AWS CLI, GCloud SDK, Colima, Docker (+ buildx/compose), GoReleaser

**CLI essentials**: git, gh, fzf, ripgrep, jq, yq, just, tmux, direnv, chezmoi, curl, wget, tree, tldr, gnupg, tree-sitter, uv

### Adding a new tool

1. Add the package to `allPackages` in `flake.nix`
2. Run `chezmoi apply` — the `check-flake` script rebuilds automatically
3. Completions regenerate if the package exposes zsh site-functions

### Adding a new dotfile

1. Create or edit the file in your home directory
2. Run `chezmoi add <file>` to start tracking it
3. Use `dot_` prefix naming, `private_` for sensitive files, `.tmpl` for templates
4. Platform-specific blocks use `{{ if eq .chezmoi.os "darwin" }}...{{ end }}`

## Configuration

### Chezmoi automation

These scripts run automatically on `chezmoi apply`:

| Script | Type | Trigger |
| ------ | ---- | ------- |
| `install-packages-v2` | run_once (before) | First apply only |
| `brewfile-install` | run_onchange (before) | Brewfile changes |
| `check-flake` | run_onchange (after) | flake.lock changes |
| `generate-completions` | run_onchange (after) | zshrc or flake.lock changes |
| `install-skills` | run_onchange (after) | Any SKILL.md changes |
| `configure-terminal` | run_once (after) | First apply only |
| `load-docker-cleanup` | run_once (after) | First apply only |

### Key directories

| Source | Target | Purpose |
| ------ | ------ | ------- |
| `dot_config/` | `~/.config/` | App configs (nvim, ghostty, etc.) |
| `dot_zsh/` | `~/.zsh/` | Zsh modules and plugins |
| `dot_claude/` | `~/.claude/` | Claude Code settings and skills |
| `private_dot_ssh/` | `~/.ssh/` | SSH config (not keys) |

### AI tools

AI coding agents are installed automatically when entering the Nix dev shell. Check versions with:

```bash
just status
```

Claude Code config lives in `dot_claude/` — settings, custom statusline, and project-scoped skills.

## Agent Skill

This repo's conventions are available as a portable agent skill:

```bash
npx skills add urmzd/dotfiles
```

All skills in this repo:

| Skill | Purpose |
| ----- | ------- |
| ai-workflows | AI-assisted workflow patterns |
| ci-cd | CI/CD pipeline conventions |
| cli-patterns | CLI conventions (JSON piping, stdout/stderr, structured logging) |
| cli-ui | Terminal UI standard (colors, spinners, symbols, layout) |
| development-practices | Coding standards and practices |
| dotfiles | Chezmoi dotfiles conventions and patterns |
| llms-txt | LLM-friendly project summary convention |
| nix-shells | Nix development shell guidance |
| pragmatic-programming | Pragmatic programming principles |
| project-scaffolding | Project structure (Justfile, .envrc, Cargo workspace, etc.) |
| readme-standards | README structure and section order |
| release-workflow | End-to-end release pipeline (sr.yaml, CI, multi-platform builds) |
| tools | Canonical tech stack reference by purpose |
| visual-identity | Branding, themes, VHS demos, teasr integration |

## License

MIT
