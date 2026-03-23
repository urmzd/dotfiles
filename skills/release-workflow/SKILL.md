---
name: release-workflow
description: End-to-end release pipeline — sr.yaml config, CI gating, multi-platform builds (GNU+musl), crates.io/PyPI publishing, post-release hooks. Use when setting up or modifying releases.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
metadata:
  title: Release Workflow
  category: development
  order: 2
---

# Release Workflow

## Release Philosophy

- Target accessibility: build for GNU (glibc) AND musl (static) Linux targets
- Users should be able to install with one command (install.sh)
- GitHub Actions where applicable (sr, embed-src, teasr expose actions)
- Every release automatically updates changelog, creates GitHub release, uploads artifacts

## sr.yaml Standard Config

Canonical filename: `sr.yaml` (not `.urmzd.sr.yml`)

```yaml
branches: [main]
tag_prefix: "v"
commit_pattern: '^(?P<type>\w+)(?:\((?P<scope>[^)]+)\))?(?P<breaking>!)?:\s+(?P<description>.+)'
types:
  - { name: feat, bump: minor, section: Features }
  - { name: fix, bump: patch, section: Bug Fixes }
  - { name: perf, bump: patch, section: Performance }
  - { name: docs, section: Documentation }
  - { name: refactor, section: Refactoring }
  - { name: revert, section: Reverts }
  - { name: chore }
  - { name: ci }
  - { name: test }
  - { name: build }
  - { name: style }
version_files: [Cargo.toml]  # or pyproject.toml, package.json — auto-detected if empty
changelog: { file: CHANGELOG.md }
stage_files: [Cargo.lock]    # or uv.lock, package-lock.json
floating_tags: true
hooks:
  commit-msg:
    - sr hook commit-msg
# Optional fields:
# build_command: "cargo build --release"
# pre_release_command: "just check"
# post_release_command: "echo released"
# prerelease: alpha              # → 1.2.0-alpha.1
# sign_tags: false
# draft: false
# release_name_template: "Release {{ version }}"
# packages: []                   # monorepo support
```

Version files by language:
- Rust: `Cargo.toml` (auto-discovers workspace members)
- Python: `pyproject.toml` (auto-discovers uv workspace members)
- Node: `package.json` (auto-discovers npm workspace members)
- Go: `*.go` files with `var Version = "..."` or `const Version string = "..."`
- Java: `pom.xml`, `build.gradle`, `build.gradle.kts`

## Release Pipeline

```
push to main
  → ci.yml (fmt → lint → test)
  → release.yml:
      embed-src (sync code in README) [if markers exist]
      → sr release (bump → changelog → tag → GitHub release)
      → build matrix (GNU + musl + Darwin + Windows)
      → publish (crates.io / PyPI / npm) [if applicable]
      → teasr (post-release demo capture) [if teasr.toml exists]
      → lockfile sync commit [skip ci]
```

## Build Targets (Accessibility First)

### Rust (7 targets)

| Target | Notes |
|--------|-------|
| `x86_64-unknown-linux-gnu` | glibc, most distros |
| `x86_64-unknown-linux-musl` | static, Alpine/containers |
| `aarch64-unknown-linux-gnu` | ARM64 glibc, Raspberry Pi/cloud |
| `aarch64-unknown-linux-musl` | ARM64 static |
| `x86_64-apple-darwin` | Intel Mac |
| `aarch64-apple-darwin` | Apple Silicon |
| `x86_64-pc-windows-msvc` | Windows |

Cross-compilation: `cross` for ARM targets on Ubuntu runners.

### Go (5 targets)

`linux/amd64`, `linux/arm64`, `darwin/amd64`, `darwin/arm64`, `windows/amd64`

Static: `CGO_ENABLED=0 go build -trimpath -ldflags "-X main.version=..."`

## Post-Release Patterns

- **Cargo.lock sync:** `cargo update --workspace` → commit `[skip ci]`
- **Asset generation:** VHS demo + screenshots (resume-generator)
- **File embedding:** embed-src → commit (openapi-generator)
- **Demo capture:** teasr → commit to `showcase/`

## Publishing

- **Crates.io:** `rust-lang/crates-io-auth-action@v1`, publish in dependency order, `sleep 30` between crates
- **PyPI:** `uv publish` or `twine upload`
- **npm:** `npm publish`

## Git Hooks

sr manages git hooks natively via `sr.yaml` — no pre-commit framework needed:

```yaml
hooks:
  commit-msg:
    - sr hook commit-msg          # validates conventional commit format
  pre-commit:
    - step: format
      patterns: ["*.rs"]
      rules:
        - "rustfmt --check --edition 2024 {files}"
    - step: lint
      patterns: ["*.rs"]
      rules:
        - "cargo clippy --workspace -- -D warnings"
```

- Hook scripts auto-synced to `.githooks/` by `sr init`
- Structured steps only run when staged files match glob `patterns`
- `{files}` in rules is replaced with matched file list

## Monorepo Support

```yaml
packages:
  - name: core
    path: crates/core
    tag_prefix: "core/v"
    version_files: [Cargo.toml]
    changelog: { file: crates/core/CHANGELOG.md }
```

Independent per-package versioning, tags, and changelogs. Target with `sr release -p core`.
