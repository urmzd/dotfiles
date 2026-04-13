---
name: scaffold-python
description: >
  Scaffold a complete Python project with CI/CD, release pipeline, justfile, sr.yaml,
  pyproject.toml, .envrc, and standard files. Uses uv, ruff, and justfile (Python lacks
  a native task runner like npm scripts, so just fills that gap). Use when creating a
  new Python CLI, library, or application, or when the user mentions "new Python project",
  "uv init", or "Python scaffold".
allowed-tools: Read Grep Glob Bash Edit Write
user-invocable: true
metadata:
  title: Scaffold Python Project
  category: development
  order: 12
---

# Scaffold Python Project

Generate a production-ready Python project following established CI/CD patterns. Read the `scaffold-project` skill first for standard files (README, AGENTS.md, LICENSE, CONTRIBUTING.md, llms.txt).

## When to Use

- Creating a new Python CLI, library, or application
- Adding CI/CD to an existing Python project missing workflows
- Standardizing a Python project to match org conventions

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
      - uses: astral-sh/setup-uv@v5
      - run: uv python install
      - run: uv sync --group dev
      - name: Check formatting
        run: uv run ruff format --check .
      - name: Run linter
        run: uv run ruff check .

  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
      - run: uv python install
      - run: uv sync --group dev
      - name: Run tests
        run: uv run pytest
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

      - uses: urmzd/sr@v4
        id: sr
        with:
          github-token: ${{ steps.app-token.outputs.token }}
          force: ${{ inputs.force }}

    outputs:
      released: ${{ steps.sr.outputs.released }}
      tag: ${{ steps.sr.outputs.tag }}
      version: ${{ steps.sr.outputs.version }}

  # Uncomment for PyPI publishing:
  # publish:
  #   needs: release
  #   if: needs.release.outputs.released == 'true'
  #   runs-on: ubuntu-latest
  #   permissions:
  #     id-token: write
  #   steps:
  #     - uses: actions/checkout@v4
  #       with:
  #         ref: ${{ needs.release.outputs.tag }}
  #     - uses: astral-sh/setup-uv@v5
  #     - run: uv python install
  #     - run: uv build
  #     - run: uv publish
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
  - pyproject.toml

changelog:
  file: CHANGELOG.md

stage_files:
  - uv.lock

floating_tags: true

hooks:
  commit-msg:
    - sr hook commit-msg
```

### `pyproject.toml`

```toml
[project]
name = "<project-name>"
version = "0.1.0"
description = ""
readme = "README.md"
license = "Apache-2.0"
requires-python = ">=3.12"
dependencies = []

[project.scripts]
# <project-name> = "<package>.cli:main"

[dependency-groups]
dev = ["pytest", "ruff", "ty"]

[tool.ruff]
line-length = 100
select = ["E", "W", "F", "I", "UP", "B", "SIM", "RUF"]

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["src"]
```

### `justfile`

```just
default: check

init:
    git config core.hooksPath .githooks
    uv sync --group dev

build:
    uv build

test:
    uv run pytest

lint:
    uv run ruff check .

fmt:
    uv run ruff format .

typecheck:
    uv run ty check src/

check: fmt lint test

run *args="":
    uv run python -m <package_name> {{args}}

record:
    teasr showme
```

Replace `<package_name>` with the actual package name.

### `.envrc`

```sh
use flake .#python
```

### `.python-version`

```
3.12
```

### Project Layout

```
src/<package_name>/
  __init__.py
  cli.py           # if CLI
  py.typed         # if library with type stubs
tests/
  __init__.py
  test_*.py
pyproject.toml
uv.lock
```

## Gotchas

- Use `uv` exclusively. No pip, pipenv, poetry, or conda
- `uv sync --group dev` installs dev dependencies; `uv sync` for production only
- `uv run` prefixes all commands to ensure they run in the project venv
- `ruff` replaces black, isort, flake8, and pyflakes. One tool for format + lint
- Python version comes from `pyproject.toml` `requires-python` field; `uv python install` resolves it
- `astral-sh/setup-uv@v5` handles caching automatically
- For PyPI publishing, `uv publish` uses trusted publishers (OIDC). Configure on pypi.org first
- `stage_files: [uv.lock]` ensures lockfile stays in sync after version bumps
