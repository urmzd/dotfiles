---
name: sync-release
description: >
  Release pipeline conventions. sr.yaml config, sr action usage, typed publishers,
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

## sr.yaml Standard Config

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
    # publish:
    #   type: cargo       # or npm, pypi, docker, go, custom
    #   workspace: true   # iterate workspace members
```

## Version Files

`version_files` (bumped by sr) and `stage_files` (committed alongside the bump, e.g. lockfiles) are language-specific. See the relevant `scaffold-<lang>` skill for the canonical values for that ecosystem. sr auto-discovers workspace members where the ecosystem supports it (Cargo, uv, pnpm/npm).

## CLI Commands

Three verbs form the release pipeline — `plan` previews, `prepare` writes bumped files to disk, `release` reconciles everything.

```
sr init         Create sr.yaml (use --merge to add new fields non-destructively)
sr plan         Terraform-style diff: planned version, tag, artifacts, publish targets
sr prepare      Bump version files + write changelog (no commit/tag/push — for CI build steps between plan and release)
sr release      Reconcile: commit, tag, push, GitHub release, upload artifacts, publish
sr config       Validate and display resolved configuration
sr migrate      Show the full version-by-version migration guide
sr completions  Generate shell completions
sr update       Update sr to the latest version
```

AI-assisted commit, PR, and review authoring live in dedicated agent skills (`ship`, `pr`, `review`). The sr CLI is release-engineering only.

### Upgrading sr

Run `sr migrate` for the full breaking-change guide. v8 turned sr into a release-state reconciler: shell hooks removed (builds live in CI), typed publishers (`cargo`/`npm`/`docker`/`pypi`/`go`/`custom`) replace `hooks.post_release`, literal paths replace globs in `artifacts`/`stage_files`, and monorepos collapse to one global version (no more `-p <pkg>`).

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
- uses: urmzd/sr@v8
  id: sr
  with:
    github-token: ${{ steps.app-token.outputs.token }}
```

**Inputs** `mode` (`plan`/`prepare`/`release`, default `release`), `dry-run` (deprecated alias for `mode: plan`), `github-token` (default `github.token`), `git-user-name` (default `sr-releaser[bot]`), `git-user-email`, `artifacts` (literal paths, space-separated), `channel`, `prerelease`, `stage-files` (literal paths), `sign-tags`, `draft`, `sha256` (checksum verification).

**Outputs** `released` (bool), `version`, `previous-version`, `tag`, `bump` (major/minor/patch), `floating-tag`, `commit-count`, `json` (full release metadata).

## Post-Release Patterns

- **Lockfile sync** language-specific lock update then commit `[skip ci]`
- **Demo capture** teasr then commit generated assets
- **File embedding** fsrc then commit

Apply only what the repo declares.

## Typed Publishers

sr runs registry uploads via `publish:` on each package — no shell hooks. Each publisher queries its registry to skip already-published versions, so re-runs are idempotent.

```yaml
packages:
  - path: .
    publish:
      type: cargo        # or npm, pypi, docker, go, custom
      workspace: true    # iterate workspace members in declaration order
```

| Type | Command | Notes |
|------|---------|-------|
| `cargo` | `cargo publish` (per workspace member when `workspace: true`) | Reads `[workspace].members` |
| `npm` | `npm publish` / `pnpm publish -r` / `yarn workspaces foreach` | Auto-detects tool by lockfile; set `access: public` for scoped packages |
| `pypi` | `uv publish` | `workspace: true` iterates `[tool.uv.workspace].members` |
| `docker` | `docker buildx build --push` | Configure `image`, `platforms`, `dockerfile` |
| `go` | No-op (Go modules publish via git tag) | sr already cuts the tag |
| `custom` | Your `command`; optional `check` to skip when already published | Receives `SR_VERSION` / `SR_TAG` env |

### Pre-release validation

Run tests, lints, and pre-flight scripts as ordinary CI steps before `sr release`. Fail the job there, not inside sr.

### Build strategy

`sr release` does not compile. Pick the shape that matches what you ship:

| Scenario | CI shape | `artifacts` in sr.yaml |
|----------|----------|------------------------|
| Pure library (no binaries) | single job: `sr release` | — |
| Single-platform binary | build then `sr release` in one job | literal path(s) to the built binary |
| Multi-platform binaries | `sr prepare` → build matrix → `sr release` (three jobs, artifacts flow via `actions/upload-artifact`) | literal paths for every target |

Multi-platform: `sr prepare` bumps version files so matrix builds embed the right version; the final `release` job downloads all matrix artifacts, commits, tags, uploads, and publishes.

## Monorepo Support

One global version across all packages — sr auto-discovers workspace members from `[workspace].members` (Cargo), `[tool.uv.workspace].members` (uv), or `pnpm-workspace.yaml` / `package.json` `workspaces`. Independent per-package versioning is no longer supported; use separate repos if packages must diverge.
