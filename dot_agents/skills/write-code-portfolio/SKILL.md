---
name: write-code-portfolio
description: >
  Personal portfolio dev-setup specifics: Nix Flakes (composable per-language shells),
  chezmoi machine polymorphism (is_macos / is_personal / is_work), Powerlevel10k zsh
  prompt, personal Neovim configuration. Use when bootstrapping a new machine in this
  portfolio, editing chezmoi-managed dotfiles, or adjusting Nix/zsh/Neovim plumbing.
  Portable picks live in write-code; this skill is the my-setup footer.
allowed-tools: Read Grep Glob Bash Edit Write
user-invocable: false
metadata:
  title: Portfolio Dev Setup
  category: development
  order: 0
---

# Portfolio Dev Setup

Personal, opinionated tooling that backs the patterns in `write-code`. This is not portable. Other users on Bitwarden + asdf + bash will not want any of this.

## Composable Toolsets (Nix Flakes)

13 reusable per-language shells combined via `flake.nix` outputs. Each shell pins a single toolchain (rust-toolchain, go, node, python with uv, etc.). Projects compose the shells they need; nothing pollutes the global env.

- Each language shell exposes a `devShell` and a `lib.tools` set for downstream composition
- Avoid `nix-direnv` here -- vanilla direnv + a `use flake` line keeps cold-start fast and predictable on macOS

## Machine Polymorphism (chezmoi)

Dotfile templates branch on host attributes:

```jinja
{{ if .is_macos -}}
# macOS-only block (Homebrew bundle, defaults write, ...)
{{ end -}}

{{ if and .is_personal (not .is_work) -}}
# personal-only block (1Password personal vault, side projects, ...)
{{ end -}}
```

Attributes come from `.chezmoi.toml.tmpl` (`is_macos`, `is_linux`, `is_personal`, `is_work`). Keep templates small and the booleans flat; deeply nested `{{ if }}` blocks are a smell.

## Powerlevel10k

Zsh prompt with instant prompt enabled and cache invalidation tied to plugin dir mtime. Source of truth: `dot_p10k.zsh` in the chezmoi source. Avoid editing the rendered `~/.p10k.zsh` directly -- it is overwritten on next `chezmoi apply`.

## Neovim (HEAD)

Lua config under `private_dot_config/nvim/`. Highlights:

- LSP set: `ty`, `ts_ls`, `lua_ls`, `gopls`, `rust_analyzer`, `jsonls`, `yamlls`, `bashls`, `jdtls`
- Subprocess-safe: detects non-interactive sessions and disables clipboard provider (so `nvim -c '...' +q` in scripts doesn't hang on macOS pbcopy)
- Plugin manager: lazy.nvim, pinned via `lazy-lock.json`
- 24-hour `compinit` cache; auto fpath discovery picks up new completions on next shell start

## Why split this out

The portable `write-code` skill answers "what should this codebase look like?" That question is the same for everyone in the org. This skill answers "how is my personal machine wired up?" -- a question only I should be making decisions for, so the router shouldn't pick it for general code-writing requests.
