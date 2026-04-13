---
name: setup-release
description: >
  Release pipeline conventions. sr.yaml config, sr action usage, git hooks, monorepo
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
# hooks:
#   pre_commit:
#     - "cargo fmt --check"
#   pre_release:
#     - "cargo test --workspace"
#   post_release:
#     - "./scripts/notify-slack.sh"
# prerelease: alpha              # → 1.2.0-alpha.1
# sign_tags: false
# draft: false
# release_name_template: "Release {{ version }}"
# channels: {}                   # trunk-based promotion
# packages: []                   # monorepo support
```

## Version Files by Language

| Language | `version_files` | `stage_files` |
|----------|----------------|---------------|
| Rust | `[Cargo.toml]` | `[Cargo.lock]` |
| Python | `[pyproject.toml]` | `[uv.lock]` |
| Node | `[package.json]` | `[package-lock.json]` |
| Go | _(none; tag only)_ | _(none)_ |

sr auto-discovers workspace members for Rust (Cargo), Python (uv), and Node (npm).

## End-to-End Workflow

```
sr worktree → sr commit → sr pr → sr review → merge → sr status → sr release
```

**CLI commands** `sr worktree` (create branch + worktree), `sr commit` (AI-powered atomic commits), `sr pr` (AI PR generation), `sr review` (AI code review), `sr status` (version + unreleased commits), `sr release` (bump + changelog + tag + GitHub release), `sr cache` (manage AI commit plan cache).

All AI commands accept `-M "context"` for additional instructions. Multiple backends supported: Claude, GitHub Copilot, Gemini (auto-detected).

## Release Pipeline

```
push to main
  → ci.yml (fmt → lint → test)
  → release.yml:
      embed-src (sync code in README) [if markers exist]
      → sr release (bump → changelog → tag → GitHub release)
      → build matrix (platform-specific; see scaffold-* skills)
      → publish (registry-specific; see scaffold-* skills)
      → teasr (post-release demo capture) [if teasr.toml exists]
      → lockfile sync commit [skip ci]
```

## sr Action Usage

```yaml
- uses: urmzd/sr@v4
  id: sr
  with:
    github-token: ${{ steps.app-token.outputs.token }}
    force: ${{ inputs.force }}
```

**Inputs** `command` (default `release`), `dry-run`, `force`, `config`, `github-token` (default `github.token`), `git-user-name` (default `sr[bot]`), `git-user-email`, `artifacts` (glob patterns), `build-command` (runs after version bump with `SR_VERSION`/`SR_TAG` env vars), `sha256` (checksum verification).

**Outputs** `released` (bool), `version`, `previous-version`, `tag`, `bump` (major/minor/patch), `floating-tag`, `commit-count`, `json` (full release metadata).

## Post-Release Patterns

- **Lockfile sync:** language-specific lock update → commit `[skip ci]`
- **Asset generation:** VHS demo + screenshots
- **File embedding:** embed-src → commit
- **Demo capture:** teasr → commit to `showcase/`

## Lifecycle Hooks

sr runs hooks at key points in every workflow command via `sr.yaml`:

```yaml
hooks:
  pre_commit:
    - "cargo fmt --check"
    - "cargo clippy --workspace -- -D warnings"
  pre_release:
    - "cargo test --workspace"
  post_release:
    - "./scripts/notify-slack.sh"
```

**Available events** `pre_commit`, `post_commit`, `pre_branch`, `post_branch`, `pre_pr`, `post_pr`, `pre_review`, `post_review`, `pre_release`, `post_release`.

- Release hooks receive `SR_VERSION` and `SR_TAG` environment variables
- Use `sr init` to generate a fully-commented `sr.yaml`; `sr init --merge` to add new fields without overwriting

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
