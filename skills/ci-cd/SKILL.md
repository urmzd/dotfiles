---
name: ci-cd
description: CI/CD patterns — ci.yml + release.yml naming, Go/Rust/Python/Node pipelines, embed-src/teasr steps, caching, concurrency. Use when setting up GitHub Actions or configuring releases.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
metadata:
  title: CI/CD Standards
  category: development
  order: 1
---

# CI/CD Standards

## Workflow Naming Convention

| File | Trigger | Purpose |
|------|---------|---------|
| `ci.yml` | `pull_request: branches: [main]` + `workflow_call` | Quality gate: fmt, lint, test |
| `release.yml` | `push: branches: [main]` + `workflow_dispatch` | Automated releases |

- No `build.yml` or `publish.yml` — build and publish are jobs within `release.yml`
- Specialized workflows allowed for domain-specific needs (e.g., `experiments.yml`)

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
- Pass `github-token: ${{ secrets.GITHUB_TOKEN }}` as secret to release workflow

## Go CI

- `actions/setup-go@v5` with `go-version-file: go.mod` and `cache: true`
- `CGO_ENABLED=0` for pure-Go projects (e.g., those using `modernc.org/sqlite`)
- `golangci/golangci-lint-action@v6` for linting
- No `version_files` in sr config — Go uses git tags only
- Build matrix: `linux/amd64`, `linux/arm64`, `darwin/amd64`, `darwin/arm64`, `windows/amd64`
- Output binaries to `bin/`

## Rust CI

- `dtolnay/rust-toolchain@stable` with `targets: ${{ matrix.target }}`
- `Swatinem/rust-cache@v2` with `key: ${{ matrix.target }}`
- `cross` (via `cargo install cross --locked`) for cross-compilation to ARM and musl targets
- Build matrix (7 targets): both glibc AND musl Linux targets
  - `x86_64-unknown-linux-gnu`, `x86_64-unknown-linux-musl`
  - `aarch64-unknown-linux-gnu`, `aarch64-unknown-linux-musl`
  - `x86_64-apple-darwin`, `aarch64-apple-darwin`, `x86_64-pc-windows-msvc`

## Python CI

- Setup: `astral-sh/setup-uv@v5`
- Format: `uv run ruff format --check .`
- Lint: `uv run ruff check .`
- Type: `uv run mypy src/`
- Test: `uv run pytest`

## Node/TS CI

- Setup: `actions/setup-node@v4` (node-version: 22)
- Build: `npm ci && npm run build`
- Lint: `npx biome check`

## embed-src CI Step (Optional)

```yaml
- uses: urmzd/embed-src@v3
  with:
    files: "README.md"
    commit-message: "chore: sync embedded files [skip ci]"
```

## teasr CI Step (Post-Release, Optional)

```yaml
- uses: urmzd/teasr/.github/actions/teasr@main
```

## Caching

- Go: `actions/setup-go@v5` built-in
- Rust: `Swatinem/rust-cache@v2` with `key: ${{ matrix.target }}`
- Python: `astral-sh/setup-uv@v5`

## Concurrency

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # CI
  # cancel-in-progress: false  # release
```

## Bot Skip

```yaml
if: github.actor != 'github-actions[bot]'
```
