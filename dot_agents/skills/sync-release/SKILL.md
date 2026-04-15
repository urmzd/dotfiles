---
name: sync-release
description: >
  Release pipeline conventions. sr.yaml config (v7), sr action usage, lifecycle hooks,
  monorepo support, post-release patterns, and version file mapping. Language-specific
  build targets and publishing live in scaffold-rust, scaffold-go, scaffold-python,
  scaffold-node. Use when setting up or modifying release pipelines.
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
- GitHub Actions where applicable (sr, fsrc, teasr expose actions)
- Every release automatically updates changelog, creates GitHub release, uploads artifacts

## sr.yaml Standard Config (v7)

Canonical filename: `sr.yaml` (not `.urmzd.sr.yml`). Use `sr init` to generate a fully-commented config.

```yaml
git:
  tag_prefix: "v"
  floating_tag: true
  sign_tags: false
  v0_protection: true

commit:
  types:
    minor:
      - feat
    patch:
      - fix
      - perf
      - refactor
    none:
      - docs
      - revert
      - chore
      - ci
      - test
      - build
      - style

changelog:
  file: CHANGELOG.md

channels:
  default: stable
  branch: main
  content:
    - name: stable

packages:
  - path: .
    version_files: []
    stage_files: []
    # hooks:
    #   pre_release:
    #     - "cargo test --workspace"
    #   post_release:
    #     - "./scripts/notify-slack.sh"
```

## Version Files by Language

| Language | `version_files` | `stage_files` |
|----------|----------------|---------------|
| Rust | `[Cargo.toml]` | `[Cargo.lock]` |
| Python | `[pyproject.toml]` | `[uv.lock]` |
| Node | `[package.json]` | `[pnpm-lock.yaml]` |
| Go | _(none; tag only)_ | _(none)_ |

sr auto-discovers workspace members for Rust (Cargo), Python (uv), and Node (pnpm/npm).

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
      fsrc (sync code in README) [if markers exist]
      → sr release (bump → changelog → tag → GitHub release)
      → build matrix (platform-specific; see scaffold-* skills)
      → publish (registry-specific; see scaffold-* skills)
      → teasr (post-release demo capture) [if teasr.toml exists]
      → lockfile sync commit [skip ci]
```

## sr Action Usage

```yaml
- uses: urmzd/sr@v7
  id: sr
  with:
    github-token: ${{ steps.app-token.outputs.token }}
    force: ${{ inputs.force }}
```

**Inputs** `dry-run`, `force`, `github-token` (default `github.token`), `git-user-name` (default `sr[bot]`), `git-user-email`, `artifacts` (glob patterns), `package` (monorepo target), `channel` (release channel), `prerelease` (pre-release identifier), `stage-files` (extra files to stage), `sign-tags`, `draft`, `sha256` (checksum verification).

**Outputs** `released` (bool), `version`, `previous-version`, `tag`, `bump` (major/minor/patch), `floating-tag`, `commit-count`, `json` (full release metadata).

## Post-Release Patterns

- **Lockfile sync:** language-specific lock update → commit `[skip ci]`
- **Demo capture:** teasr → commit to `showcase/`
- **File embedding:** fsrc → commit

## Lifecycle Hooks

sr runs per-package hooks at key points in the release lifecycle via `sr.yaml`:

```yaml
packages:
  - path: .
    hooks:
      pre_release:
        - "cargo test --workspace"
      post_release:
        - "./scripts/notify-slack.sh"
```

**Available events** `pre_release`, `post_release`.

- Release hooks receive `SR_VERSION` and `SR_TAG` environment variables
- Use `sr init` to generate a fully-commented `sr.yaml`; `sr init --merge` to add new fields without overwriting

## Monorepo Support

```yaml
packages:
  - path: crates/core
    tag_prefix: "core/v"
    version_files: [Cargo.toml]
```

Independent per-package versioning, tags, and changelogs. Target with `sr release -p core`.
