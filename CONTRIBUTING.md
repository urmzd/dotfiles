# Contributing

Thanks for your interest in contributing to **dotfiles**.

## Prerequisites

- **macOS or Linux**
- **[Nix](https://nixos.org/download.html)** with flakes enabled
- **[chezmoi](https://www.chezmoi.io/install/)**
- **[just](https://github.com/casey/just)** — command runner
- **[GH_TOKEN](https://cli.github.com/)** — GitHub CLI authentication

## Getting Started

```sh
git clone https://github.com/urmzd/dotfiles.git
cd dotfiles
```

## Development

| Command | What it does |
|---------|-------------|
| `chezmoi diff` | Preview pending changes |
| `chezmoi apply` | Apply dotfile changes |
| `just update` | Update Nix flake inputs |
| `just status` | Check environment status |
| `just check` | Run project checks |

## Commit Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/) enforced via [sr](https://github.com/urmzd/sr):

| Prefix | Purpose |
|--------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `refactor` | Refactoring |
| `chore` | Maintenance |
| `ci` | CI changes |

Format: `type(scope): description` — scope by tool/area (e.g., `feat(nvim):`, `fix(zsh):`, `chore(brew):`)

## Pull Requests

1. Fork the repository
2. Create a feature branch (`feat/your-feature`)
3. Test with `chezmoi diff` before applying
4. Push to your fork and open a Pull Request
5. Keep PRs focused — one logical change per PR

## Code Style

- Shell scripts: POSIX-compatible where possible, bash/zsh when needed
- Templates: Use `{{ .chezmoi.os }}` guards for platform-specific blocks
- Prefer `justfile` targets over raw shell scripts for common tasks
- Never commit secrets, API keys, or tokens
