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
version_files: [Cargo.toml]  # or pyproject.toml, package.json
changelog: { file: CHANGELOG.md }
stage_files: [Cargo.lock]    # or uv.lock, package-lock.json
floating_tags: true
```

Version files by language:
- Rust: `Cargo.toml`
- Python: `pyproject.toml`
- Node: `package.json`
- Go: tags only (no version file)

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

## Pre-commit Hook

```yaml
repos:
  - repo: https://github.com/urmzd/semantic-release
    rev: v{version}
    hooks:
      - id: conventional-commit-msg
```
