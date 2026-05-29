---
name: write-code
description: >
  Operational tech-stack picks and coding patterns: error handling, testing strategy,
  commit conventions, interface design, junior-friendly bias. Use when writing or
  reviewing implementation code. (Personal Nix / chezmoi setup lives in write-code-portfolio.)
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: Development Practices
  category: development
  order: 0
---

# Development Practices

> **Layering:** Operational picks that satisfy `review-design` (principles) and `assess-quality` (foundational framework). Use this skill when you need a concrete answer for "what tool/pattern/idiom"; use `review-design` when reasoning about tradeoffs; use `assess-quality` for the underlying "why."

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
| Observability | opentelemetry (tracing/metrics/logs), structlog + stdlib logging (Python; loguru for scripts only) |
| Editor | Neovim (HEAD) with LSP: ty, ts_ls, lua_ls, gopls, rust_analyzer, jsonls, yamlls, bashls, jdtls |
| Shell | Zsh + Oh My Zsh + Powerlevel10k |
| Terminal Multiplexer | tmux (vi-mode, vim-tmux-navigator) |
| DevOps | Terraform, kubectl, Helm, k9s, AWS CLI 2 |
| Dev Environment | Per-language version manager + direnv + a dotfile manager (my setup: Nix Flakes + chezmoi -- see write-code-portfolio) |

## Commit Style

Angular Conventional Commits (validated by CI lint; `ship` skill handles AI-assisted authoring):

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

- **Convention over configuration** placeholder comments (`<project>`) over complex templating
- **Composable toolsets** combine reusable per-language toolsets (e.g. Nix flakes, devcontainers)
- **Machine polymorphism** dotfile templates branch on host attributes (OS, role). See write-code-portfolio for the chezmoi-specific implementation.
- **Minimal package-manager footprint** prefer reproducible/pinned installs; reach for OS package managers (Homebrew, apt) only for OS-specific tools
- **Subprocess safety** editors and TUIs should detect non-interactive environments and disable host integrations (e.g. clipboard)
- **Shell cold-start hygiene** cache expensive completion setup; auto-discover fpath/plugins

## My setup

For my personal portfolio specifics (Nix Flakes shells, chezmoi machine polymorphism, Powerlevel10k, Neovim), see the **write-code-portfolio** skill.
