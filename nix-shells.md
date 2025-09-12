# Nix Development Shells

This document describes the available Nix development environments that replace asdf functionality.

## Quick Start

```bash
# Enable direnv (one-time setup)
nix run .#setup

# Allow direnv in this directory
direnv allow

# Now the environment will automatically activate when you cd into the directory
```

## Available Development Shells

### Default Shell
```bash
nix develop
# or just `cd` into the directory with direnv enabled
```
Basic tools: git, fzf, ripgrep, tree, curl, wget, jq, yq, direnv

### Language-Specific Shells

#### Node.js Development
```bash
nix develop .#node
```
**Includes:** Node.js 20, npm, yarn, pnpm, TypeScript, language servers, Claude Code CLI

**Replaces:** `asdf install nodejs 23.9.0`

#### Python Development  
```bash
nix develop .#python
```
**Includes:** Python 3.13, pip, virtualenv, pipx, black, flake8, mypy, pytest, ruff, uv

**Replaces:** `asdf install python 3.13.5`

#### Rust Development
```bash
nix develop .#rust
```
**Includes:** rustc, cargo, rustfmt, clippy, rust-analyzer, cargo extensions

**Replaces:** `asdf install rust stable`

#### Go Development
```bash
nix develop .#go
```
**Includes:** Go compiler, gopls, golangci-lint, gotools, migration tools

#### Lua Development
```bash
nix develop .#lua
```
**Includes:** Lua 5.4, luacheck, stylua, lua-language-server

**Replaces:** `asdf install lua 5.4.7`

#### DevOps/Infrastructure
```bash
nix develop .#devops
```
**Includes:** Terraform, Ansible, Docker, kubectl, helm, k9s, AWS CLI, Google Cloud SDK

**Replaces:** `asdf install terraform 1.12.2`

#### Data Science
```bash
nix develop .#data
```
**Includes:** Python with pandas/numpy/jupyter, R with tidyverse

#### Full Environment
```bash
nix develop .#full
```
All tools and languages combined.

## Integration with Existing Workflow

### Migration from asdf

Instead of:
```bash
asdf install nodejs 23.9.0
asdf global nodejs 23.9.0
```

Use:
```bash
nix develop .#node
# or set up direnv for automatic activation
```

### Per-Project Environments

Create a `.envrc` file in any project:
```bash
# For Node.js projects
echo "use flake /path/to/dotfiles#node" > .envrc
direnv allow

# For Python projects  
echo "use flake /path/to/dotfiles#python" > .envrc
direnv allow
```

### Reproducible Project Shells

Create a `flake.nix` in your project that extends the base environments:

```nix
{
  inputs.dotfiles.url = "path:/Users/urmzd/.dotfiles";
  
  outputs = { self, dotfiles }: {
    devShells.default = dotfiles.devShells.x86_64-darwin.node.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ [ 
        # Project-specific dependencies
      ];
    });
  };
}
```

## Advantages over asdf

1. **Reproducible:** Exact versions pinned in flake.lock
2. **Isolated:** No global state conflicts
3. **Fast:** Cached builds, instant shell activation with direnv
4. **Comprehensive:** Includes language servers, formatters, linters
5. **Composable:** Mix and match environments
6. **Cross-platform:** Works on Linux, macOS, and WSL

## Direnv Integration

With direnv enabled, environments activate automatically:

```bash
cd ~/projects/my-node-app     # Node environment auto-activates
cd ~/projects/my-python-app   # Python environment auto-activates  
cd ~/                         # Back to system default
```

## Troubleshooting

### Enable Nix Flakes
```bash
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Install direnv
```bash
# macOS
brew install direnv

# Add to shell config
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
```

### Force Rebuild
```bash
nix develop .#node --rebuild
```

### List Available Shells
```bash
nix flake show
```