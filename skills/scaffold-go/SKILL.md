---
name: scaffold-go
description: >
  Scaffold a complete Go project with CI/CD, release pipeline, Makefile, sr.yaml,
  .envrc, and standard files. Uses go toolchain and make as the native build system.
  Use when creating a new Go CLI, service, or module, or when the user mentions
  "new Go project", "go mod init", or "Go scaffold".
allowed-tools: Read Grep Glob Bash Edit Write
user-invocable: true
metadata:
  title: Scaffold Go Project
  category: development
  order: 11
---

# Scaffold Go Project

Generate a production-ready Go project following established CI/CD patterns. Read the `scaffold-project` skill first for standard files (README, AGENTS.md, LICENSE, CONTRIBUTING.md, llms.txt).

## When to Use

- Creating a new Go CLI tool, HTTP service, or library module
- Adding CI/CD to an existing Go project missing workflows
- Standardizing a Go project to match org conventions

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
  fmt:
    name: Format
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
      - name: Check formatting
        run: |
          unformatted=$(gofmt -l .)
          if [ -n "$unformatted" ]; then
            echo "The following files are not formatted:"
            echo "$unformatted"
            exit 1
          fi

  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
      - uses: golangci/golangci-lint-action@v7

  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
      - run: go test ./...
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

  build:
    needs: release
    if: needs.release.outputs.released == 'true'
    name: Build (${{ matrix.goos }}/${{ matrix.goarch }})
    runs-on: ${{ matrix.runner }}
    permissions:
      contents: write
    env:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    strategy:
      fail-fast: true
      matrix:
        include:
          - goos: linux
            goarch: amd64
            runner: ubuntu-latest
            artifact_suffix: -linux-amd64
          - goos: linux
            goarch: arm64
            runner: ubuntu-latest
            artifact_suffix: -linux-arm64
          - goos: darwin
            goarch: amd64
            runner: macos-15-intel
            artifact_suffix: -darwin-amd64
          - goos: darwin
            goarch: arm64
            runner: macos-15
            artifact_suffix: -darwin-arm64
          - goos: windows
            goarch: amd64
            runner: windows-latest
            artifact_suffix: -windows-amd64.exe
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ needs.release.outputs.tag }}

      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod

      - name: Build static binary
        shell: bash
        env:
          GOOS: ${{ matrix.goos }}
          GOARCH: ${{ matrix.goarch }}
          CGO_ENABLED: "0"
        run: |
          BIN_NAME="${{ github.event.repository.name }}"
          go build -trimpath \
            -ldflags "-X main.version=${{ needs.release.outputs.version }} -X main.commit=${{ github.sha }} -X main.date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            -o "build/bin/${BIN_NAME}${{ matrix.artifact_suffix }}" ./cmd/${BIN_NAME}

      - name: Upload to release
        shell: bash
        run: |
          BIN_NAME="${{ github.event.repository.name }}"
          gh release upload "${{ needs.release.outputs.tag }}" "build/bin/${BIN_NAME}${{ matrix.artifact_suffix }}" --clobber
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

floating_tags: true

hooks:
  commit-msg:
    - sr hook commit-msg
```

No `version_files` — Go uses git tags only. No `stage_files` — `go.sum` changes are committed during development, not release.

### `Makefile`

```makefile
.PHONY: all init build test lint fmt check run install record

MOD := $(shell basename $(CURDIR))
CMD := cmd/$(MOD)

all: check

init:
	git config core.hooksPath .githooks
	go mod download && go mod tidy

build:
	CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o bin/$(MOD) ./$(CMD)

test:
	go test ./...

lint:
	golangci-lint run

fmt:
	gofmt -w .

check: fmt lint test

run: build
	./bin/$(MOD)

install:
	CGO_ENABLED=0 go install -trimpath -ldflags="-s -w" ./$(CMD)

record:
	teasr showme
```

For complex projects (multi-service repos, code generation, protobuf), add a justfile to handle orchestration that Make handles poorly (dependency ordering, parameterized recipes).

### `.envrc`

```sh
use flake .#go
```

### Project Layout

```
cmd/<project-name>/    # main package (entry point)
  main.go
internal/              # private packages
pkg/                   # public packages (if library)
go.mod
go.sum
```

## Gotchas

- Always use `go-version-file: go.mod` instead of hardcoding Go versions
- `CGO_ENABLED=0` for static binaries — required for pure-Go projects, especially those using `modernc.org/sqlite`
- Inject version/commit/date via `-ldflags "-X main.version=..."` — declare `var version, commit, date string` in main.go
- No `version_files` in sr.yaml — Go versioning is tag-only
- `golangci-lint-action@v7` auto-detects Go version from go.mod
- Bot skip uses `github.actor != 'github-actions[bot]'` or `'sr-releaser[bot]'` depending on which bot triggers
- Cross-compilation is native in Go — no `cross` tool needed, just set `GOOS`/`GOARCH`
