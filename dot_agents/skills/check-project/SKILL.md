---
name: check-project
description: >
  Validate project structure against scaffold conventions -- check for required files,
  CI consistency, optional directory usage, and documentation completeness. Use to audit
  an existing project or verify a scaffold was applied correctly.
allowed-tools: Read Grep Glob Bash
user-invocable: true
metadata:
  title: Check Project
  category: development
  order: 5
---

# Check Project

Audit a project against the conventions defined in `scaffold-project`, `write-readme`, and the language-specific scaffold skills. Report PASS/WARN/FAIL per check with actionable fix suggestions.

## Required Files

Every project must have these. Report FAIL if missing:

| File | What to Check |
|------|---------------|
| `README.md` | Exists; has centered header block |
| `AGENTS.md` | Exists |
| `LICENSE` | Exists; contains "Apache" |
| `CONTRIBUTING.md` | Exists |
| `sr.yaml` | Exists; has `floating_tags: true` and `tag_prefix: "v"` |
| `.envrc` | Exists; contains `use flake` |
| `llms.txt` | Exists |
| `skills/*/SKILL.md` | At least one skill exists |
| `.github/workflows/ci.yml` | Exists (or `terraform.yml` for Terraform projects) |
| `.github/workflows/release.yml` | Exists (or `terraform.yml` for Terraform projects) |

## CI Consistency

Check workflow files for convention compliance. Report FAIL if violated:

| Check | Expected |
|-------|----------|
| ci.yml `permissions` | `contents: read` at workflow level |
| ci.yml `workflow_call` | Present in `on:` triggers |
| ci.yml concurrency | `cancel-in-progress: true` |
| release.yml concurrency | `cancel-in-progress: false` |
| release.yml CI gate | `uses: ./.github/workflows/ci.yml` |
| release.yml bot skip | `github.actor != 'sr[bot]'` |
| release.yml force dispatch | `workflow_dispatch` with `force` boolean input |

## Optional Directory Checks

Report WARN (not FAIL) when conventions suggest a directory should exist:

| Condition | Expected |
|-----------|----------|
| `teasr.toml` exists | `showcase/` directory should exist |
| Project is a library (has `pkg/`, exports in package.json, or `[project.scripts]` in pyproject.toml) | `examples/` directory should exist |
| Project has API routes or consumes external APIs | `spec/` directory should exist |
| `examples/` exists | `examples/basic/` (or equivalent simplest example) should exist |

## README Checks

Report WARN if:

| Check | Expected |
|-------|----------|
| Demo image path | References `showcase/` (not `assets/`) |
| Quick Start section | Exists with "Quick Start" heading |
| fsrc markers | Not stale (content between markers matches referenced files) |
| Section order | Features before Installation before Quick Start |

## Sub-Package Checks

For workspace projects (Cargo workspace, npm workspaces, etc.), audit each publishable member. Report FAIL if missing:

| Check | Expected |
|-------|----------|
| `LICENSE` in each workspace member | Exists; matches root `LICENSE` |
| `README.md` in each workspace member | Exists; has crate name as heading |

Skip `examples/` workspace members — they are not published independently.

## How to Run

1. Detect the project language from manifest files (Cargo.toml, go.mod, pyproject.toml, package.json, main.tf)
2. Run all required file checks
3. Run CI consistency checks
4. Run optional directory checks based on detected project type
5. If workspace detected, run sub-package checks on each publishable member
6. Run README checks
6. Report results grouped by severity: FAIL first, then WARN, then PASS

## Output Format

```
## Project Audit: {project-name}

### FAIL (must fix)
- [ ] Missing AGENTS.md -- create with project architecture and key interfaces
- [ ] ci.yml missing `permissions: contents: read` -- add at workflow level

### WARN (should fix)
- [ ] teasr.toml exists but no showcase/ directory -- run `teasr showme` or `just record`
- [ ] Library project without examples/ -- add examples/basic/ with minimal usage

### PASS
- [x] README.md with centered header
- [x] sr.yaml with floating_tags and v prefix
- [x] CI gates release, bot skip present
```
