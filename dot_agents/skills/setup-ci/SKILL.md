---
name: setup-ci
description: >
  Defines GitHub Actions workflow structure: ci.yml + release.yml naming, concurrency
  groups, bot-commit skip, workflow_call reuse, App-token checkout, and optional
  fsrc/teasr steps. Language-specific pipelines live in scaffold-rust, scaffold-go,
  scaffold-python, scaffold-node, scaffold-terraform. Use when setting up GitHub Actions,
  wiring ci.yml/release.yml, configuring concurrency or workflow_call, or adding fsrc/teasr
  steps. Do NOT use for sr.yaml schema, typed publishers, or the sr CLI/action; use
  sync-release for those.
allowed-tools: Read, Grep, Glob, Bash(git *), Bash(gh *), Edit, Write
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

- **No `build.yml` or `publish.yml`** build and publish are jobs within `release.yml`
- Specialized workflows allowed for domain-specific needs (e.g., `experiments.yml`)
- Exception: Terraform uses a single `terraform.yml` (see `scaffold-terraform`)

## Pipeline Flow

```text
PR -> ci.yml (fmt -> lint -> test)
Push main -> release.yml:
  fsrc -> ci -> sr release -> build -> publish -> teasr
```

sr v9+ syncs lock files (`Cargo.lock`, `uv.lock`, `poetry.lock`, `package-lock.json`) during the version bump and commits them in the release commit, so `release.yml` needs no separate lock sync step or `[skip ci]` lock commit. See `sync-release` for details.

## Release Config

- Canonical filename: `sr.yaml` (not `.urmzd.sr.yml`)
- `floating_tags: true` in all configs
- `tag_prefix: "v"` and Angular commit pattern
- See `sync-release` for full sr.yaml reference

## Concurrency

```yaml
# CI workflows: cancel stale runs
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# Release workflows: never cancel mid-release
concurrency:
  group: release
  cancel-in-progress: false
```

## Bot Skip

Prevent infinite loops from bot commits:

```yaml
if: github.actor != 'sr[bot]'
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

Release workflows use a GitHub App (sr-releaser) for bot commits that can trigger further workflows. The release job runs in the `release` environment, which holds the app's private key and only `main` can use:

```yaml
release:
  needs: ci
  runs-on: ubuntu-latest
  environment: release
  steps:
    - name: Generate app token
      id: app-token
      uses: actions/create-github-app-token@64ab729a6294000f5aa4a4bc0b73d1f32bc45510 # v3.3.0
      with:
        client-id: Iv23liUsXGDICnIdo3Ev
        private-key: ${{ secrets.SR_RELEASER_PRIVATE_KEY }}
        repositories: ${{ github.event.repository.name }}

    - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      with:
        fetch-depth: 0
        token: ${{ steps.app-token.outputs.token }}
```

Do not read `secrets.SR_RELEASER_APP_ID` or a repo-level `SR_RELEASER_PRIVATE_KEY`. Only `urmzd/infra` keeps those. In any other repo the job fails with `Input required and not supplied: app-id`.

### Register a new repo for releases

A new repo has no `release` environment and no key. Terraform in `urmzd/infra` creates both. Do this before the first release:

1. In `urmzd/infra`, add the repo name to `managed_repos` in `variables.tf`. This creates the `release` environment, limits it to `main`, and stores `SR_RELEASER_PRIVATE_KEY` in it.
2. If the repo is public, also add it to `public_repos`. This adds the `main-protection` ruleset: `main` then needs a pull request, and admins and sr-releaser bypass it.
3. Open a pull request. Read the plan preview comment. It must show only resources for the new repo.
4. Merge it. Terraform applies on `main`.
5. Check the result: `gh api repos/urmzd/<repo>/environments/release/secrets --jq '.secrets[].name'` prints `SR_RELEASER_PRIVATE_KEY`.

## Pinned Actions

Pin every third-party action to a full commit SHA, with the release in a trailing comment:

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
```

- **Why.** A tag such as `@v7` can be moved to new code. A commit SHA cannot. A moved tag is how the tj-actions compromise reached its users.
- **What counts as third party.** Everything outside `urmzd/*`, including `actions/*`. Our own actions (`urmzd/sr@v9`, `urmzd/fsrc@v4`) stay on their major tag.
- **Which release.** The newest release that is at least 14 days old. A release that is only days old has not been vetted by anyone.
- **Branch-style refs.** `dtolnay/rust-toolchain@stable` is a branch. Pin the commit at the head of `stable` and keep `# stable` as the comment. That commit defaults to the stable toolchain.
- **Resolve a SHA.** `gh api repos/<owner>/<repo>/commits/<tag> --jq .sha` prints the commit for a tag. Do not copy a SHA from a web page or another repo.
- **Before you bump a major.** Read the release notes of every major you skip, and check that the inputs you pass still exist in the action's `action.yml` at the new commit.

Pins go stale. Add Dependabot so they do not. It updates the SHA and the comment together. Set the cooldown to match the 14-day rule: without it, Dependabot proposes a release after 3 days.

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    cooldown:
      default-days: 14
```

A cooldown does not delay security updates.

## fsrc Step (Optional)

Sync code snippets into README before release:

```yaml
- uses: urmzd/fsrc@v4
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
