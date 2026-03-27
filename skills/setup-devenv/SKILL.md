---
name: setup-devenv
description: 13 composable Nix development shells for reproducible tooling. Use when setting up dev environments, configuring .envrc files, or adding Nix shells to projects.
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: Nix Dev Shells
  category: cli
  order: 0
---

# Nix Dev Shells

## Overview

All development environments are managed through Nix Flakes, providing reproducible, composable toolsets per language. Enter any shell with:

```bash
nix develop .#<shell>
```

## Available Shells

| Shell | Purpose |
|-------|---------|
| `default` | Base tools only |
| `node` | Node.js 22, npm/yarn/pnpm |
| `python` | Python 3.12, uv |
| `rust` | Rust stable, cargo, clippy |
| `go` | Go, golangci-lint |
| `devops` | Terraform, kubectl, Helm, k9s, AWS CLI 2 |
| `lua` | Lua 5.4, luarocks, stylua |
| `haskell` | GHC, cabal, stack |
| `ruby` | Ruby, bundler |
| `scheme` | Guile Scheme |
| `perl` | Perl with core modules |
| `java` | Java 21, Gradle/Maven |
| `full` | All of the above combined |

## Base Tools (Every Shell)

Every shell includes a common set of CLI tools:

- **git**, **gh** — version control and GitHub CLI
- **fzf** — fuzzy finder
- **ripgrep** — fast search
- **jq**, **yq** — JSON/YAML processing
- **just** — command runner
- **direnv** — per-directory environment variables
- **chezmoi** — dotfile management
- **tmux** — terminal multiplexer
- **tree-sitter** — incremental parsing
- **uv** — Python package manager (available everywhere)

## Usage with direnv

Projects use `.envrc` files with `use flake .#<shell>` to automatically activate the correct Nix shell when entering the directory:

```bash
# .envrc
use flake .#rust
```

Combined with direnv, this means the right tools are always available without manual shell activation.
