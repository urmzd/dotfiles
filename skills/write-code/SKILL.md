---
name: write-code
description: Tech stack, coding patterns, commit conventions, interface design, error handling, testing, and junior-friendly philosophy. Use when writing code, making commits, or choosing tools/patterns.
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: Development Practices
  category: development
  order: 0
---

# Development Practices

## Development Philosophy

- "How easy is this for a junior to understand, develop, and expand on?"
- Self-documenting code > comments
- Small, focused interfaces > god objects
- Convention over configuration
- Explicit > implicit

## Tech Stack

| Category | Tools |
|----------|-------|
| Languages | Rust, Go, TypeScript/Node 22, Python 3.13, Lua 5.4, Java 21, Haskell |
| Package Managers | cargo, uv (Python), npm/yarn/pnpm, luarocks |
| Formatters/Linters | biome (JS/TS), stylua (Lua), clippy (Rust), golangci-lint (Go), ruff (Python) |
| Editor | Neovim (HEAD) with LSP: basedpyright, ts_ls, lua_ls, gopls, rust_analyzer, jsonls, yamlls, bashls, jdtls |
| Shell | Zsh + Oh My Zsh + Powerlevel10k |
| Terminal Multiplexer | tmux (vi-mode, vim-tmux-navigator) |
| DevOps | Terraform, kubectl, Helm, k9s, AWS CLI 2 |
| Dev Environment | Nix Flakes (13 composable shells), direnv, chezmoi |

## Commit Style

Angular Conventional Commits, enforced via `sr commit` and `sr hook commit-msg`:

```
type(scope): lowercase imperative description (max 72 chars)
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`, `bump`

**Rules**:
- Imperative mood ("add", not "added"), no trailing period
- Body explains **why**, not what
- One logical change per commit, every file in exactly one commit
- Order: infrastructure/config → core library → features → tests → docs
- Footer: `BREAKING CHANGE:`, `Closes #N`, `Fixes #N`, `Refs #N`

## Interface Design (Go SDKs)

- **Sealed interfaces:** unexported marker methods (`isMessage()`, `isDelta()`)
- **Functional options:** `New(WithX(...), WithY(...))`
- **Provider pattern:** `Provider` interface → `provider/{name}/` adapters
- **Channel-based streaming:** `ChatStream() (<-chan Delta, error)`

## Error Handling

| Language | Approach |
|----------|----------|
| Rust | `thiserror` (libraries), `anyhow` (CLI/apps), `.context()`, no `unsafe` |
| Go | structured errors, `errors.Is()`/`errors.As()`, sentinel errors, `IsTransient()` helper |
| Python | standard exceptions, pytest assertions |

## Testing

For comprehensive testing guidance (test types, fixtures, mocks, CI strategy), see the `test-code` skill.

| Language | Framework | Pattern | CI Command |
|----------|-----------|---------|------------|
| Rust | `cargo test` | `#[cfg(test)]` + `tests/` integration | `cargo test --workspace` |
| Go | `testing` | `_test.go`, table-driven | `go test ./...` |
| Python | `pytest` | `tests/test_*.py`, class-based | `uv run pytest` |

## Workspace Organization

- **Rust:** `crates/` with core → impl → cli
- **Go:** `cmd/` for binaries, root or `internal/` for packages
- **Python:** `src/` layout with hatchling

## Coding Patterns

- **Convention over configuration** — placeholder comments (`<project>`) over complex templating
- **Composable toolsets** — Nix flakes combine reusable per-language toolsets
- **Machine polymorphism** — chezmoi templates adapt to `is_macos`/`is_linux`/`is_personal`/`is_work`
- **Minimal Homebrew** — Nix for reproducibility, Homebrew only for macOS-specific tools
- **Subprocess safety** — Neovim detects non-interactive environments and disables clipboard
- **ZSH caching** — 24-hour compinit cache, auto fpath discovery for completions
