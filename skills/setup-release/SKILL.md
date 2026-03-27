---
name: setup-release
description: >
  Release pipeline conventions — sr.yaml config, sr action usage, git hooks, monorepo
  support, post-release patterns, and version file mapping. Language-specific build
  targets and publishing live in scaffold-rust, scaffold-go, scaffold-python, scaffold-node.
  Use when setting up or modifying release pipelines.
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: Release Workflow
  category: development
  order: 2
---

# Release Workflow

Universal release conventions. For language-specific build matrices, publish steps, and sr.yaml templates, see the corresponding `scaffold-*` skill.

## Release Philosophy

- Target accessibility: build for multiple platforms (Linux, macOS, Windows)
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

## Version Files by Language

| Language | `version_files` | `stage_files` |
|----------|----------------|---------------|
| Rust | `[Cargo.toml]` | `[Cargo.lock]` |
| Python | `[pyproject.toml]` | `[uv.lock]` |
| Node | `[package.json]` | `[package-lock.json]` |
| Go | _(none — tag only)_ | _(none)_ |

sr auto-discovers workspace members for Rust (Cargo), Python (uv), and Node (npm).

## Release Pipeline

```
push to main
  → ci.yml (fmt → lint → test)
  → release.yml:
      embed-src (sync code in README) [if markers exist]
      → sr release (bump → changelog → tag → GitHub release)
      → build matrix (platform-specific — see scaffold-* skills)
      → publish (registry-specific — see scaffold-* skills)
      → teasr (post-release demo capture) [if teasr.toml exists]
      → lockfile sync commit [skip ci]
```

## sr Action Usage

```yaml
- uses: urmzd/sr@v2
  id: sr
  with:
    github-token: ${{ steps.app-token.outputs.token }}
    force: ${{ inputs.force }}
```

Outputs: `released` (bool), `tag` (e.g. `v1.2.0`), `version` (e.g. `1.2.0`).

## Post-Release Patterns

- **Lockfile sync:** language-specific lock update → commit `[skip ci]`
- **Asset generation:** VHS demo + screenshots
- **File embedding:** embed-src → commit
- **Demo capture:** teasr → commit to `showcase/`

## Git Hooks

sr manages git hooks natively via `sr.yaml` — no pre-commit framework needed:

```yaml
hooks:
  commit-msg:
    - sr hook commit-msg          # validates conventional commit format
  pre-commit:
    - step: format
      patterns: ["*.rs"]          # only runs when matching files are staged
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
