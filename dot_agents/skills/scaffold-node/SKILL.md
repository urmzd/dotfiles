---
name: scaffold-node
description: >
  Scaffold a complete Node/TypeScript project with CI/CD, release pipeline, sr.yaml,
  .envrc, and standard files. Uses pnpm and biome. Loads on top of scaffold-project
  (run that first for cross-language standard files). Use when creating a new
  Node.js app, TypeScript library, or website, or when the user mentions "new Node project",
  "pnpm init", "TypeScript scaffold", or "Astro site". Do NOT use for Go, Rust,
  Python, or Terraform projects; use the matching scaffold-<lang> skill.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(pnpm *), Bash(npx *), Bash(git *)
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
          node-version: 24
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
          node-version: 24
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
          node-version: 24
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
          node-version: 24
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

      - uses: urmzd/sr@v9
        id: sr
        with:
          github-token: ${{ steps.app-token.outputs.token }}
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}       # needed only if sr.yaml declares publish: { type: npm }

    outputs:
      released: ${{ steps.sr.outputs.released }}
      tag: ${{ steps.sr.outputs.tag }}
      version: ${{ steps.sr.outputs.version }}

```

To enable npm publishing, add `publish: { type: npm, workspace: true, access: public }` to `sr.yaml` (below). The sr npm publisher auto-detects pnpm/npm/yarn from the lockfile.

`pnpm-lock.yaml` records workspace deps as `link:` and stores no member versions, so a bump never makes it stale: no `stage_files` entry and no post-release `pnpm install` commit. sr v9 does rewrite workspace sibling ranges (such as `^1.0.0`) in member `package.json` files, and, for npm projects, the root and member entries in `package-lock.json`.

### `sr.yaml`

See `sync-release` skill for full sr.yaml reference.

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
    # Uncomment to publish to npm (the npm publisher auto-detects pnpm/yarn
    # from the lockfile and runs the tool's native recursive publish):
    # publish:
    #   type: npm
    #   workspace: true     # pnpm publish -r / npm publish --workspaces
    #   access: public      # needed for scoped @org/pkg on first publish
```

### `pnpm-workspace.yaml`

Every Node repo has one, even single-package repos. pnpm 11 reads its settings
from here, not from `package.json` or `.npmrc`.

```yaml
# Skip versions published in the last 24h; most malicious releases are pulled
# within that window.
minimumReleaseAge: 1440

# Deny by default. Allow a dependency's install script only when it needs one
# and you have checked why; add a comment saying so.
allowBuilds:
  esbuild: true

# Security pins live here, never in package.json ("pnpm.overrides" is ignored
# by pnpm 11 and silently dropped from the lockfile).
overrides: {}
```

Add `packages:` only for monorepos.

### `package.json` pins

```json
{
  "packageManager": "pnpm@11.6.0",
  "engines": { "node": ">=24" }
}
```

Never commit `package-lock.json`, `yarn.lock`, or `bun.lock`. Run `pnpm import`
then delete the old lockfile when converting an npm project.

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
use fnm  # Loads the version pinned in .nvmrc
PATH_add node_modules/.bin
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
- `ERR_PNPM_IGNORED_BUILDS` means a dependency wants an install script. pnpm also writes `<pkg>: set this to true or false` into `pnpm-workspace.yaml`; replace that line with an explicit `true` or `false` in the existing `allowBuilds` map, or the file gets a duplicate key and every command fails
- A lockfile entry younger than `minimumReleaseAge` fails `pnpm install` and `pnpm run`. If the bump was intended, wait out the 24h or regenerate locally with `--config.minimumReleaseAge=0`; never lower the setting in the repo
- `astro check` needs `@astrojs/check` and `typescript` as devDependencies. Without them it logs an error and exits 0 in CI, so the check silently does nothing
- `biome check` handles both formatting and linting in one pass
- `biome check --write` to auto-fix (replaces `prettier --write` + `eslint --fix`)
- Node 24 is the current LTS. Use `node-version: 24`
- `cache: pnpm` in setup-node handles caching automatically
- `pnpm/action-setup@v4` must come before `actions/setup-node` in CI
- For framework-specific type checks (e.g., `astro check`), add a separate `check` job
- `cancel-in-progress: false` on release workflow to prevent partial releases
- For monorepos, use `turbo run <task>` instead of running tasks per-package manually
