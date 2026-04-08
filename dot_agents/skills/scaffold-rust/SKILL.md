---
name: scaffold-rust
description: >
  Scaffold a complete Rust project with CI/CD, release pipeline, and sr.yaml.
  Uses cargo as the native build system. Use when creating a new
  Rust CLI, library, or workspace, or when the user mentions "new Rust project",
  "cargo init", or "Rust scaffold".
allowed-tools: Read Grep Glob Bash Edit Write
user-invocable: true
metadata:
  title: Scaffold Rust Project
  category: development
  order: 10
---

# Scaffold Rust Project

Generate a production-ready Rust project following established CI/CD patterns. Read the `scaffold-project` skill first for standard files (README, AGENTS.md, LICENSE, CONTRIBUTING.md, llms.txt).

## When to Use

- Creating a new Rust CLI tool, library, or workspace
- Adding CI/CD to an existing Rust project missing workflows
- Standardizing a Rust project to match org conventions

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

env:
  CARGO_TERM_COLOR: always

jobs:
  check:
    name: Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - run: cargo check --workspace

  clippy:
    name: Clippy
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy
      - uses: Swatinem/rust-cache@v2
      - run: cargo clippy --workspace -- -D warnings

  fmt:
    name: Format
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: rustfmt
      - run: cargo fmt --all -- --check

  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - run: cargo test --workspace
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

jobs:
  ci:
    if: github.actor != 'sr-releaser[bot]'
    uses: ./.github/workflows/ci.yml

  release:
    needs: ci
    runs-on: ubuntu-latest
    permissions:
      contents: write
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
    name: Build (${{ matrix.target }})
    runs-on: ${{ matrix.runner }}
    permissions:
      contents: write
    env:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    strategy:
      matrix:
        include:
          - target: x86_64-unknown-linux-gnu
            runner: ubuntu-latest
            cross: false
          - target: aarch64-unknown-linux-gnu
            runner: ubuntu-latest
            cross: true
          - target: x86_64-unknown-linux-musl
            runner: ubuntu-latest
            cross: false
          - target: aarch64-unknown-linux-musl
            runner: ubuntu-latest
            cross: true
          - target: x86_64-apple-darwin
            runner: macos-15-intel
            cross: false
          - target: aarch64-apple-darwin
            runner: macos-15
            cross: false
          - target: x86_64-pc-windows-msvc
            runner: windows-latest
            cross: false
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ needs.release.outputs.tag }}

      - uses: dtolnay/rust-toolchain@stable
        with:
          targets: ${{ matrix.target }}

      - uses: Swatinem/rust-cache@v2
        with:
          key: ${{ matrix.target }}

      - name: Install musl-tools
        if: matrix.target == 'x86_64-unknown-linux-musl'
        run: sudo apt-get update && sudo apt-get install -y musl-tools

      - name: Install cross
        if: matrix.cross
        run: cargo install cross --locked

      - name: Build
        shell: bash
        run: |
          BIN_NAME="${{ github.event.repository.name }}"
          if [ "${{ matrix.cross }}" = "true" ]; then
            cross build --release --target ${{ matrix.target }}
          else
            cargo build --release --target ${{ matrix.target }}
          fi

      - name: Upload to release
        shell: bash
        run: |
          BIN_NAME="${{ github.event.repository.name }}"
          TAG="${{ needs.release.outputs.tag }}"
          if [ -f "target/${{ matrix.target }}/release/${BIN_NAME}.exe" ]; then
            cp "target/${{ matrix.target }}/release/${BIN_NAME}.exe" "${BIN_NAME}-${{ matrix.target }}.exe"
            gh release upload "$TAG" "${BIN_NAME}-${{ matrix.target }}.exe" --clobber
          else
            cp "target/${{ matrix.target }}/release/${BIN_NAME}" "${BIN_NAME}-${{ matrix.target }}"
            chmod +x "${BIN_NAME}-${{ matrix.target }}"
            gh release upload "$TAG" "${BIN_NAME}-${{ matrix.target }}" --clobber
          fi

  # Uncomment for crates.io publishing:
  # publish:
  #   needs: release
  #   if: needs.release.outputs.released == 'true'
  #   runs-on: ubuntu-latest
  #   permissions:
  #     id-token: write
  #     contents: read
  #   steps:
  #     - uses: actions/checkout@v4
  #       with:
  #         ref: ${{ needs.release.outputs.tag }}
  #     - uses: dtolnay/rust-toolchain@stable
  #     - uses: Swatinem/rust-cache@v2
  #     - id: auth
  #       uses: rust-lang/crates-io-auth-action@v1
  #     - name: Publish
  #       env:
  #         CARGO_REGISTRY_TOKEN: ${{ steps.auth.outputs.token }}
  #       run: cargo publish --allow-dirty
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
  - Cargo.toml

changelog:
  file: CHANGELOG.md

stage_files:
  - Cargo.lock

floating_tags: true

hooks:
  commit-msg:
    - sr hook commit-msg
```

For workspaces, list all member `Cargo.toml` files in `version_files`.

### Common Commands

No justfile. Cargo is the native build system:

```sh
cargo fmt --all           # format
cargo clippy --workspace -- -D warnings  # lint
cargo test --workspace    # test
cargo build --release     # build
cargo run -- <args>       # run
```

Set up git hooks during init: `git config core.hooksPath .githooks && cargo fetch`

For complex projects (workspaces with many crates, custom build steps, cross-compilation), add a justfile to orchestrate multi-step workflows that cargo alone can't express.

## Demo Recording

For projects with a justfile, add a `record` recipe:

```just
record:
    teasr showme
```

For projects recording their own CLI, build first:

```just
record: build
    PATH="$(pwd)/target/release:$PATH" teasr showme
```

Without a justfile, run `teasr showme` directly.

## Gotchas

- Always use `--workspace` for clippy/test/check in multi-crate repos
- `cross` is only needed for ARM targets (`aarch64-*`); x86 musl just needs `musl-tools`
- `macos-15-intel` for x86_64 Darwin, `macos-15` for aarch64 Darwin
- Sleep 30s between `cargo publish` calls in workspace publish order (crates.io rate limit)
- Use `-p <crate-name>` for `cargo build`/`cargo publish` when the workspace has multiple binaries
- `cancel-in-progress: false` on release workflow to prevent partial releases
