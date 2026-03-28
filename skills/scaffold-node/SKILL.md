---
name: scaffold-node
description: >
  Scaffold a complete Node/TypeScript project with CI/CD, release pipeline, justfile,
  sr.yaml, .envrc, and standard files. Uses npm and biome. Use when creating a new
  Node.js app, TypeScript library, or website, or when the user mentions "new Node project",
  "npm init", "TypeScript scaffold", or "Astro site".
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

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - name: Check formatting & lint
        run: npx biome check

  typecheck:
    name: Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npx tsc --noEmit

  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npm run build

  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npm test
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
    if: github.actor != 'sr-releaser[bot]'
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

      - uses: urmzd/sr@v2
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
  #     - uses: actions/setup-node@v4
  #       with:
  #         node-version: 22
  #         registry-url: https://registry.npmjs.org
  #     - run: npm ci
  #     - run: npm publish
  #       env:
  #         NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### `sr.yaml`

```yaml
branches:
  - main

tag_prefix: "v"

commit_pattern: '^(?P<type>\w+)(?:\((?P<scope>[^)]+)\))?(?P<breaking>!)?:\s+(?P<description>.+)'

breaking_section: Breaking Changes
misc_section: Miscellaneous

types:
  - name: feat
    bump: minor
    section: Features
  - name: fix
    bump: patch
    section: Bug Fixes
  - name: perf
    bump: patch
    section: Performance
  - name: docs
    section: Documentation
  - name: refactor
    section: Refactoring
  - name: revert
    section: Reverts
  - name: chore
  - name: ci
  - name: test
  - name: build
  - name: style

version_files:
  - package.json

changelog:
  file: CHANGELOG.md

stage_files:
  - package-lock.json

floating_tags: true

hooks:
  commit-msg:
    - sr hook commit-msg
```

### `justfile`

```just
default: check

init:
    git config core.hooksPath .githooks
    npm ci

build:
    npm run build

test:
    npm test

lint:
    npx biome check

fmt:
    npx biome check --write

typecheck:
    npx tsc --noEmit

check: fmt lint typecheck test

run *args="":
    npm start -- {{args}}

dev:
    npm run dev
```

### `.envrc`

```sh
use flake .#node
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

- Replace `npm test` with `npm run check` (framework-specific checks like `astro check`)
- Add build artifact upload for deployment workflows
- Add deploy job if using AWS S3/CloudFront (see `scaffold-terraform` for infra)

### pnpm Projects

Replace npm commands:
- `actions/setup-node` → add `pnpm/action-setup@v4` before it
- `npm ci` → `pnpm install --frozen-lockfile`
- `npx` → `pnpm exec`
- `stage_files: [pnpm-lock.yaml]` in sr.yaml

### Monorepo Variant (Turbo)

For multi-package repos, add turbo for cached, parallel task execution:

- `npm install turbo --save-dev` at workspace root
- Add `turbo.json` with pipeline definitions (`build`, `test`, `lint`, `typecheck`)
- Replace direct `npm run` calls with `turbo run` in justfile and CI
- Turbo caches task outputs — subsequent runs skip unchanged packages

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

- Use `npm ci` (not `npm install`) in CI for reproducible installs
- `biome check` handles both formatting and linting in one pass
- `biome check --write` to auto-fix (replaces `prettier --write` + `eslint --fix`)
- Node 22 is the current LTS — use `node-version: 22`
- `cache: npm` in setup-node handles caching automatically
- For framework-specific type checks (e.g., `astro check`), add a separate `check` job
- `cancel-in-progress: false` on release workflow to prevent partial releases
- For monorepos, use `turbo run <task>` instead of running tasks per-package manually
