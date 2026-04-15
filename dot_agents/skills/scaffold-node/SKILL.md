---
name: scaffold-node
description: >
  Scaffold a complete Node/TypeScript project with CI/CD, release pipeline, sr.yaml,
  .envrc, and standard files. Uses pnpm and biome. Use when creating a new
  Node.js app, TypeScript library, or website, or when the user mentions "new Node project",
  "pnpm init", "TypeScript scaffold", or "Astro site".
allowed-tools: Read Grep Glob Bash Edit Write
user-invocable: true
metadata:
  title: Scaffold Node/TypeScript Project
  category: development
  order: 13
---

# Scaffold Node/TypeScript Project

Generate a production-ready Node/TypeScript project following established CI/CD patterns. Read the `scaffold-project` skill first for standard files (README, AGENTS.md, LICENSE, CONTRIBUTING.md, llms.txt).

## When to Use

- Creating a new Node.js CLI, library, web app, or static site
- Adding CI/CD to an existing Node/TypeScript project missing workflows
- Standardizing a Node project to match org conventions

## Generated Files

### `.github/workflows/ci.yml`

```yaml
name: CI

on:
  pull_request:
    branches: [main]
  workflow_call:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - name: Check formatting & lint
        run: pnpm exec biome check

  typecheck:
    name: Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm exec tsc --noEmit

  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm run build

  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm test
```

### `.github/workflows/release.yml`

```yaml
name: Release

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      force:
        description: "Re-release the current tag (use when a previous release partially failed)"
        type: boolean
        default: false

concurrency:
  group: release
  cancel-in-progress: false

permissions:
  contents: write

jobs:
  ci:
    if: github.actor != 'sr[bot]'
    uses: ./.github/workflows/ci.yml

  release:
    needs: ci
    runs-on: ubuntu-latest
    steps:
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

      - uses: urmzd/sr@v7
        id: sr
        with:
          github-token: ${{ steps.app-token.outputs.token }}
          force: ${{ inputs.force }}

    outputs:
      released: ${{ steps.sr.outputs.released }}
      tag: ${{ steps.sr.outputs.tag }}
      version: ${{ steps.sr.outputs.version }}

  # Uncomment for npm publishing:
  # publish:
  #   needs: release
  #   if: needs.release.outputs.released == 'true'
  #   runs-on: ubuntu-latest
  #   steps:
  #     - uses: actions/checkout@v4
  #       with:
  #         ref: ${{ needs.release.outputs.tag }}
  #     - uses: pnpm/action-setup@v4
  #     - uses: actions/setup-node@v4
  #       with:
  #         node-version: 22
  #         registry-url: https://registry.npmjs.org
  #     - run: pnpm install --frozen-lockfile
  #     - run: pnpm publish --no-git-checks
  #       env:
  #         NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### `sr.yaml`

See `sync-release` skill for full sr.yaml reference (v7 format).

```yaml
git:
  tag_prefix: "v"
  floating_tag: true

commit:
  types:
    minor: [feat]
    patch: [fix, perf, refactor]
    none: [docs, revert, chore, ci, test, build, style]

changelog:
  file: CHANGELOG.md

packages:
  - path: .
    version_files:
      - package.json
    stage_files:
      - pnpm-lock.yaml
```

### `package.json` scripts

```json
{
  "scripts": {
    "build": "tsc",
    "test": "vitest run",
    "lint": "biome check",
    "fmt": "biome check --write",
    "typecheck": "tsc --noEmit",
    "check": "pnpm run fmt && pnpm run lint && pnpm run typecheck && pnpm test",
    "record": "teasr showme",
    "dev": "tsc --watch"
  }
}
```

Use `pnpm run <task>` for all operations. pnpm is the package manager.

### `.envrc`

```sh
use flake .#js
```

### `biome.json`

```json
{
  "$schema": "https://biomejs.dev/schemas/2.0.0/schema.json",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true
    }
  }
}
```

## Variants

### Static Sites (Astro, Next.js)

- Replace `pnpm test` with `pnpm run check` (framework-specific checks like `astro check`)
- Add build artifact upload for deployment workflows
- Add deploy job if using AWS S3/CloudFront (see `scaffold-terraform` for infra)

### Monorepo Variant (Turbo)

For multi-package repos, add turbo for cached, parallel task execution:

- `pnpm add turbo --save-dev -w` at workspace root
- Add `turbo.json` with pipeline definitions (`build`, `test`, `lint`, `typecheck`)
- Replace direct `pnpm run` calls with `turbo run` in scripts and CI
- Turbo caches task outputs; subsequent runs skip unchanged packages

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": { "dependsOn": ["^build"], "outputs": ["dist/**"] },
    "test": { "dependsOn": ["build"] },
    "lint": {},
    "typecheck": {}
  }
}
```

## Gotchas

- Use `pnpm install --frozen-lockfile` (not `pnpm install`) in CI for reproducible installs
- `biome check` handles both formatting and linting in one pass
- `biome check --write` to auto-fix (replaces `prettier --write` + `eslint --fix`)
- Node 22 is the current LTS. Use `node-version: 22`
- `cache: pnpm` in setup-node handles caching automatically
- `pnpm/action-setup@v4` must come before `actions/setup-node` in CI
- For framework-specific type checks (e.g., `astro check`), add a separate `check` job
- `cancel-in-progress: false` on release workflow to prevent partial releases
- For monorepos, use `turbo run <task>` instead of running tasks per-package manually
