# Essence

Shared, project-agnostic reference material for the dotfiles repository.

## Tech Stack

| Category | Tools |
|----------|-------|
| Languages | Rust, Go, TypeScript/Node 22, Python 3.13, Lua 5.4, Java 21, Haskell |
| Package Managers | cargo, uv (Python), npm/yarn/pnpm, luarocks |
| Formatters/Linters | biome (JS/TS), stylua (Lua), clippy (Rust), golangci-lint (Go) |
| Editor | Neovim (HEAD) with LSP: basedpyright, ts_ls, lua_ls, gopls, rust_analyzer, jsonls, yamlls, bashls, jdtls |
| Shell | Zsh + Oh My Zsh + Powerlevel10k |
| Terminal Multiplexer | tmux (vi-mode, vim-tmux-navigator) |
| AI Tools | Claude Code (opus), OpenAI Codex, Google Gemini CLI, GitHub Copilot |
| DevOps | Terraform, kubectl, Helm, k9s, AWS CLI 2 |
| Dev Environment | Nix Flakes (13 composable shells), direnv, chezmoi |

## Nix Dev Shells

Entry point: `nix develop .#<shell>`

Shells: `default`, `node`, `python`, `rust`, `go`, `devops`, `lua`, `haskell`, `ruby`, `scheme`, `perl`, `java`, `full`

Every shell includes: git, gh, fzf, ripgrep, jq, yq, just, direnv, chezmoi, tmux, tree-sitter, uv

## Commit Style

Angular Conventional Commits enforced via `git-ai commit` (AI-powered commit generator, aliased as `gai`).

```
type(scope): lowercase imperative description (max 72 chars)
```

**Types**: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert, bump

**Rules**:
- Imperative mood ("add", not "added"), no trailing period
- Body explains WHY, not what
- One logical change per commit, every file in exactly one commit
- Order: infrastructure/config -> core library -> features -> tests -> docs
- Footer: `BREAKING CHANGE:`, `Closes #N`, `Fixes #N`, `Refs #N`

## Coding Patterns

- **Convention over configuration**: placeholder comments (`<project>`) over complex templating
- **Composable toolsets**: Nix flakes combine reusable per-language toolsets
- **Machine polymorphism**: chezmoi templates adapt to `is_macos`/`is_linux`/`is_personal`/`is_work`
- **Minimal Homebrew**: Nix for reproducibility, Homebrew only for macOS-specific tools
- **Subprocess safety**: Neovim detects non-interactive environments and disables clipboard
- **ZSH caching**: 24-hour compinit cache, auto fpath discovery for completions

## Visual Identity

- **Theme**: Cyberdream (256-color)
- **Font**: MonaspiceNe Nerd Font (16pt)
- **VHS demos**: 1200x700, 24px padding, 50ms typing speed, branded splash card

## CI/CD Standards

### 3-Workflow Pattern

Every project uses three workflow files:

| File | Trigger | Purpose |
|------|---------|---------|
| `ci.yml` | `pull_request: branches: [main]` + `workflow_call` | Quality gate: lint + test |
| `build.yml` | `push: tags: ["v*"]` | Cross-platform artifact builds, uploaded to GitHub release |
| `release.yml` | `push: branches: [main]` | Calls `ci.yml`, then `urmzd/semantic-release@v1` |

### Go-specific patterns

- `actions/setup-go@v5` with `go-version-file: go.mod` and `cache: true`
- `CGO_ENABLED=0` for pure-Go projects (e.g., those using `modernc.org/sqlite`)
- `golangci/golangci-lint-action@v6` for linting
- No `version_files` in semantic-release config — Go uses git tags only (no `go.mod` version field)
- Build matrix: `linux/amd64`, `linux/arm64`, `darwin/amd64`, `darwin/arm64`
- Output binaries to `bin/` (Go convention)

### Rust-specific patterns

- `dtolnay/rust-toolchain@stable` with `targets: ${{ matrix.target }}`
- `Swatinem/rust-cache@v2` with `key: ${{ matrix.target }}`
- `cross` (via `cargo install cross --locked`) for cross-compilation to ARM and musl targets
- Build matrix must include **both** glibc AND musl Linux targets:
  - `x86_64-unknown-linux-musl` (static, musl)
  - `x86_64-unknown-linux-gnu` (glibc, no cross needed)
  - `aarch64-unknown-linux-musl` (ARM static, cross)
  - `aarch64-unknown-linux-gnu` (ARM glibc, cross)
  - `x86_64-apple-darwin`, `aarch64-apple-darwin`, `x86_64-pc-windows-msvc`

### Common patterns

- Releases: `urmzd/semantic-release@v1` via `uses: urmzd/semantic-release/.github/workflows/release.yml@v1`
- Config file: `.urmzd.sr.yml` at repo root
- `floating_tags: true` in all semantic-release configs
- `tag_prefix: "v"` and Angular commit pattern
- Pass `github-token: ${{ secrets.GITHUB_TOKEN }}` as secret to release workflow

## Contents

| File | Purpose |
|------|---------|
| `tools.md` | Canonical tech stack: languages, build tools, and key libraries |
| `vhs/demo-template.tape` | Starter VHS tape for recording terminal demos with consistent branding |
