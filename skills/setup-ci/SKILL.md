---
name: setup-ci
description: >
  CI/CD conventions — ci.yml + release.yml naming, concurrency, bot skip, embed-src/teasr
  steps, and workflow structure. Language-specific pipelines live in scaffold-rust,
  scaffold-go, scaffold-python, scaffold-node, scaffold-terraform. Use when setting up
  GitHub Actions or understanding CI conventions.
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: CI/CD Standards
  category: development
  order: 1
---

# CI/CD Standards

Universal conventions that apply across all languages. For language-specific CI jobs, build matrices, and caching, see the corresponding `scaffold-*` skill.

## Workflow Naming Convention

| File | Trigger | Purpose |
|------|---------|---------|
| `ci.yml` | `pull_request: branches: [main]` + `workflow_call` | Quality gate: fmt, lint, test |
| `release.yml` | `push: branches: [main]` + `workflow_dispatch` | Automated releases |

- No `build.yml` or `publish.yml` — build and publish are jobs within `release.yml`
- Specialized workflows allowed for domain-specific needs (e.g., `experiments.yml`)
- Exception: Terraform uses a single `terraform.yml` (see `scaffold-terraform`)

## Pipeline Flow

```
PR → ci.yml (fmt → lint → test)
Push main → release.yml:
  embed-src → ci → sr release → build → publish → teasr → lock sync
```

## Release Config

- Canonical filename: `sr.yaml` (not `.urmzd.sr.yml`)
- `floating_tags: true` in all configs
- `tag_prefix: "v"` and Angular commit pattern
- See `setup-release` for full sr.yaml reference

## Concurrency

```yaml
# CI workflows — cancel stale runs
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# Release workflows — never cancel mid-release
concurrency:
  group: release
  cancel-in-progress: false
```

## Bot Skip

Prevent infinite loops from bot commits:

```yaml
if: github.actor != 'sr-releaser[bot]'
```

## CI Reuse Pattern

`ci.yml` exposes `workflow_call` so `release.yml` can gate on it:

```yaml
# ci.yml
on:
  pull_request:
    branches: [main]
  workflow_call:

# release.yml
jobs:
  ci:
    uses: ./.github/workflows/ci.yml
  release:
    needs: ci
```

## App Token Pattern

Release workflows use a GitHub App for bot commits that can trigger further workflows:

```yaml
- name: Generate app token
  id: app-token
  uses: actions/create-github-app-token@v1
  with:
    app-id: ${{ secrets.SR_RELEASER_APP_ID }}
    private-key: ${{ secrets.SR_RELEASER_PRIVATE_KEY }}
    repositories: ${{ github.event.repository.name }}

- uses: actions/checkout@v4
  with:
    fetch-depth: 0
    token: ${{ steps.app-token.outputs.token }}
```

## embed-src Step (Optional)

Sync code snippets into README before release:

```yaml
- uses: urmzd/embed-src@v3
  with:
    files: "README.md"
    commit-message: "chore: sync embedded files [skip ci]"
```

## teasr Step (Post-Release, Optional)

Capture terminal demo after release:

```yaml
- uses: urmzd/teasr/.github/actions/teasr@main
```

## Force Re-release

All release workflows support manual dispatch with a `force` flag for partial failures:

```yaml
workflow_dispatch:
  inputs:
    force:
      description: "Re-release the current tag (use when a previous release partially failed)"
      type: boolean
      default: false
```
