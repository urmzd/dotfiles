---
name: setup-devenv
description: Per-language toolchain + direnv guidance. Use when setting up a project's dev environment, configuring .envrc files, or choosing between version managers.
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: Per-Language Dev Environments
  category: cli
  order: 0
---

# Per-Language Dev Environments

## Philosophy

System-installed CLIs (git, gh, fzf, jq, kubectl, terraform, ...) come from Homebrew on macOS or apt/dnf/pacman on Linux. Per-language runtime versions come from the best-in-class tool for that language. No polyglot abstraction layer.

## Runtime version managers

| Language | Tool | Project pin | Notes |
|----------|------|-------------|-------|
| Node | [fnm](https://github.com/Schniz/fnm) | `.nvmrc` | `eval "$(fnm env --use-on-cd)"` in shell rc auto-switches |
| Python | [uv](https://docs.astral.sh/uv/) | `.python-version` + `pyproject.toml` | `uv venv` + `uv sync` |
| Rust | [rustup](https://rustup.rs) | `rust-toolchain.toml` | Auto-installs the pinned channel |
| Go | system `go` | `go.mod` go directive | One toolchain per machine usually fine |
| Lua | system `lua` | n/a | Pin via Brewfile/apt |

## .envrc patterns (vanilla direnv, no nix-direnv)

The standard direnv idioms cover most needs:

```bash
# Python: auto-create + activate .venv on cd
layout python

# Node with fnm: load .nvmrc-pinned version
use fnm

# Add project-local bin/ to PATH
PATH_add bin

# Load KEY=VALUE pairs from .env
dotenv

# Inherit ~/.envrc (which sources ~/.envrc.local for personal defaults)
source_up
```

See `~/.local/share/chezmoi/dot_envrc.project.example` for a working template.

## When to add an upstream installer

Adopt a chezmoi `run_onchange_after_install-<tool>.sh.tmpl` script with a pinned version when:

- The tool ships security/auth fixes faster than distro repos can package them (gcloud, aws-cli)
- The vendor distributes only via their own installer with no version-arg support (Snowflake Cortex)
- Reproducibility across machines matters more than the convenience of `brew upgrade`

Mirror the structure of `run_onchange_after_install-cloud-clis.sh.tmpl` or `run_onchange_after_install-cortex.sh.tmpl`. Pin the version at the top in ALL_CAPS, install to `~/.local/share/<tool>/<version>/`, symlink into `~/.local/bin`.

## When NOT to add a polyglot version manager

asdf / mise / rtx solve the problem of "I want one config to pin Node + Python + Go + Rust." If the per-language tools above already cover your needs without that abstraction, don't add it. Polyglot managers add another layer of indirection (shims, plugin updates, slower shell startup). Only adopt one when project pinning matters across enough languages to outweigh that cost.
