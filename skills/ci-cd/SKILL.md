---
name: ci-cd
description: 3-workflow CI/CD pattern for Go, Rust, and Node projects. Use when setting up GitHub Actions, creating release workflows, or configuring semantic-release.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
metadata:
  title: CI/CD Standards
  category: development
  order: 1
---

# CI/CD Standards

## 3-Workflow Pattern

Every project uses three workflow files:

| File | Trigger | Purpose |
|------|---------|---------|
| `ci.yml` | `pull_request: branches: [main]` + `workflow_call` | Quality gate: lint + test |
| `build.yml` | `push: tags: ["v*"]` | Cross-platform artifact builds, uploaded to GitHub release |
| `release.yml` | `push: branches: [main]` | Calls `ci.yml`, then `urmzd/semantic-release@v1` |

## Go-Specific Patterns

- `actions/setup-go@v5` with `go-version-file: go.mod` and `cache: true`
- `CGO_ENABLED=0` for pure-Go projects (e.g., those using `modernc.org/sqlite`)
- `golangci/golangci-lint-action@v6` for linting
- No `version_files` in semantic-release config — Go uses git tags only (no `go.mod` version field)
- Build matrix: `linux/amd64`, `linux/arm64`, `darwin/amd64`, `darwin/arm64`
- Output binaries to `bin/` (Go convention)

## Rust-Specific Patterns

- `dtolnay/rust-toolchain@stable` with `targets: ${{ matrix.target }}`
- `Swatinem/rust-cache@v2` with `key: ${{ matrix.target }}`
- `cross` (via `cargo install cross --locked`) for cross-compilation to ARM and musl targets
- Build matrix must include **both** glibc AND musl Linux targets:
  - `x86_64-unknown-linux-musl` (static, musl)
  - `x86_64-unknown-linux-gnu` (glibc, no cross needed)
  - `aarch64-unknown-linux-musl` (ARM static, cross)
  - `aarch64-unknown-linux-gnu` (ARM glibc, cross)
  - `x86_64-apple-darwin`, `aarch64-apple-darwin`, `x86_64-pc-windows-msvc`

## Common Patterns

- Releases: `urmzd/semantic-release@v1` via `uses: urmzd/semantic-release/.github/workflows/release.yml@v1`
- Config file: `.urmzd.sr.yml` at repo root
- `floating_tags: true` in all semantic-release configs
- `tag_prefix: "v"` and Angular commit pattern
- Pass `github-token: ${{ secrets.GITHUB_TOKEN }}` as secret to release workflow
