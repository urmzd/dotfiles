# dotfiles

Modern dotfiles managed with Chezmoi and Nix, with minimal Homebrew for macOS-only tooling.

## Quick Start

### One-command setup (macOS recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/urmzd/.dotfiles/main/bootstrap-nix-chezmoi.sh | bash
```

### Manual setup
```bash
# Clone
git clone https://github.com/urmzd/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Bootstrap
./bootstrap-nix-chezmoi.sh
```

If you already have chezmoi installed and want to initialize directly:
```bash
chezmoi init --apply https://github.com/urmzd/.dotfiles.git
```

## Usage

### Apply and update dotfiles
```bash
chezmoi diff
chezmoi apply
```

### Edit templates safely
```bash
chezmoi edit ~/.zshrc
chezmoi edit ~/.gitconfig
chezmoi edit ~/.config/nvim/init.lua
```

### Nix development shells
```bash
nix develop          # default shell
nix develop .#node   # Node.js
nix develop .#python # Python
nix develop .#full   # full toolchain
```

### Homebrew packages (macOS)
```bash
brew bundle --file Brewfile
```

### Update Nix inputs
```bash
just update
```

## Verification

Quick checks after setup:
```bash
chezmoi --version
nix --version
nvim --version
```

Optional smoke tests:
```bash
./cross-platform-test.sh
./security-audit.sh
```

## Repo layout

```text
bootstrap-nix-chezmoi.sh        # main installer
Brewfile                        # macOS-only packages
flake.nix                       # Nix dev shells
justfile                        # update/security helpers
requirements-pipx.txt           # pipx-managed tools
security-audit.sh               # security audit wrapper
cross-platform-test.sh          # toolchain smoke test
run_once_*.sh.tmpl              # chezmoi hooks

dot_config/                     # XDG config templates (nvim, tmux, direnv)
dot_zshrc.tmpl                  # shell config template
private_dot_ssh/                # SSH templates (encrypted when needed)
```
