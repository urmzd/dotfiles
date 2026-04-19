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

## Version Files

`version_files` (bumped by sr) and `stage_files` (committed alongside the bump, e.g. lockfiles) are language-specific. See the relevant `scaffold-<lang>` skill for the canonical values for that ecosystem. sr auto-discovers workspace members where the ecosystem supports it (Cargo, uv, pnpm/npm).

## CLI Commands (v7)

```
sr init         Create sr.yaml (use --merge to add new fields non-destructively)
sr status       Show unreleased commits, next version, changelog preview, open PRs
sr config       Validate and display resolved configuration
sr release      Bump → changelog → tag → GitHub release (trunk flow)
sr migrate      Show the full version-by-version migration guide
sr completions  Generate shell completions
sr update       Update sr to the latest version
```

AI-assisted commit, PR, and review authoring live in dedicated agent skills (`ship`, `pr`, `review`). The sr CLI is release-engineering only as of v7.

### Upgrading sr

Run `sr migrate` to view the full breaking-change guide for every version transition (3.x → 7.x). v7 redesigned `sr.yaml` into 6 top-level sections (`git`, `commit`, `changelog`, `channels`, `vcs`, `packages`), removed the MCP server, and removed all AI CLI commands.

## Release Pipeline

```
push to main
  → ci.yml (fmt → lint → test)
  → release.yml:
      fsrc (sync embedded sources) [if markers exist]
      → sr release (bump → changelog → tag → GitHub release)
      → build / publish [language and registry specific; see scaffold-* skills]
      → teasr (post-release demo capture) [if teasr.toml exists]
      → lockfile sync commit [skip ci; if the ecosystem has a lockfile]
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

- **Lockfile sync** language-specific lock update then commit `[skip ci]`
- **Demo capture** teasr then commit generated assets
- **File embedding** fsrc then commit

Apply only what the repo declares.

## Lifecycle Hooks

sr runs per-package hooks at key points in the release lifecycle via `sr.yaml`:

```yaml
packages:
  - path: .
    hooks:
      pre_release:
        - "cargo test --workspace"
      build:
        - "cargo build --release"
      post_release:
        - "cargo publish"
```

**Available events** (in execution order):

| Event | When it runs |
|-------|-------------|
| `pre_release` | Before any mutation — tests, lints, validations that may abort the release |
| `build` | After version files are bumped, before git commit/tag — compile artifacts from bumped sources |
| `post_release` | After GitHub release and artifact upload — publish to registries |

- Hooks receive `SR_VERSION` and `SR_TAG` environment variables
- When `hooks.build` is set, every declared `artifacts` glob must resolve to ≥1 file before the tag is created
- Use `sr init` to generate a fully-commented `sr.yaml`; `sr init --merge` to add new fields without overwriting

### Build strategy

`hooks.build` runs as a single process on one runner. Pick the pattern that matches what you ship:

| Scenario | `hooks.build` | `artifacts` | External matrix |
|----------|--------------|-------------|-----------------|
| Pure library (no binaries) | — | — | — |
| Single-platform binary | `cargo build --release` | `target/release/mytool` | — |
| Multi-platform binaries (cross-compile) | — | `release-assets/*` | **runs in CI before sr** |

Cross-platform matrices need multiple runners (macOS for darwin, Windows for windows). Run the matrix in GitHub Actions `strategy.matrix`, deposit outputs in a known directory, then call sr — sr is agnostic to how artifacts are produced.

## Monorepo Support

```yaml
packages:
  - path: crates/core
    tag_prefix: "core/v"
    version_files: [Cargo.toml]
```

Independent per-package versioning, tags, and changelogs. Target with `sr release -p core`.
