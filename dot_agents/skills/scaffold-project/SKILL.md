---
name: scaffold-project
description: >
  Generates cross-language standard files (README, AGENTS.md, LICENSE,
  CONTRIBUTING.md, SECURITY.md, sr.yaml, .envrc, llms.txt), documentation
  conventions, and project structure, then dispatches to language-specific
  scaffolds. Use first for cross-language standard files and structure, THEN load
  the matching scaffold-<lang> skill (scaffold-rust, scaffold-go, scaffold-python,
  scaffold-node, scaffold-terraform) for CI/CD, release pipelines, and tooling. Use
  when creating or standardizing projects. Do NOT use alone for a single-language
  project; co-load the matching scaffold-<lang> skill for its CI/CD and tooling.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(git *)
metadata:
  title: Project Scaffolding
  category: development
  order: 4
---

# Project Scaffolding

## Development Philosophy

Every project should be understandable by a junior developer. Self-documenting structure. Skills as documentation. Minimal setup friction.

## Language-Specific Scaffolds

After generating standard files, load the appropriate language skill for CI/CD, release, and tooling:

| Language | Skill | Key Tools |
|----------|-------|-----------|
| Rust | `scaffold-rust` | cargo, clippy, rustfmt, cross, crates.io |
| Go | `scaffold-go` | go, golangci-lint, gofmt |
| Python | `scaffold-python` | uv, ruff, pytest, ty |
| Node/TS | `scaffold-node` | pnpm, biome, tsc |
| Terraform | `scaffold-terraform` | terraform, AWS OIDC |

Always generate the standard files below first, then apply the language-specific scaffold.

## Standard Files (Every Project)

| File | Purpose |
|------|---------|
| `README.md` | Human-facing documentation (see `write-readme`) |
| `AGENTS.md` | AI-facing project context (see `configure-ai`) |
| `LICENSE` | Apache-2.0 (standard for all repos) |
| `CONTRIBUTING.md` | How to contribute (see template below) |
| `CODE_OF_CONDUCT.md` | Contributor Covenant 2.1 (see `community-health`) |
| `SECURITY.md` | Vulnerability reporting policy (see `community-health`) |
| `.github/pull_request_template.md` | Standard PR template (see `community-health`) |
| `.github/ISSUE_TEMPLATE/` | Bug report + feature request forms + config (see `community-health`) |
| `sr.yaml` | Semantic release config |
| `.envrc` | direnv config (per-language `layout`, env vars, `dotenv`) |
| `llms.txt` | LLM-friendly project summary (see `create-llms-txt`) |
| `skills/<name>/SKILL.md` | Agent skill instructions |
| `docs/` | Project documentation; layout and templates owned by `scaffold-docs` |
| `.ai-memory/` | Tool-agnostic AI memory (see `memory` skill) |
| `.github/workflows/ci.yml` | Quality gate |
| `.github/workflows/release.yml` | Automated releases |
| `teasr.toml` | Demo recording config (optional -- add for CLIs/visual output; see `style-brand`) |
| `showcase/` | Demo assets: demo.gif, demo.png, feature captures (optional -- add with teasr.toml) |
| `examples/` | Runnable example code (optional -- add for libraries/SDKs/configurable tools) |
| `spec/` | API specifications (optional -- add when project exposes/consumes a formal API) |

## Task Runner Convention

Prefer native build systems over justfile. Add a justfile only when project complexity demands orchestration beyond what the native tools provide.

| Language | Native Task Runner | When to Add justfile |
|----------|-------------------|----------------------|
| Node/TS | `pnpm` scripts in `package.json` | Monorepo orchestration, multi-step deploys |
| Rust | `cargo` commands | Multi-crate workspaces, cross-compilation |
| Go | `Makefile` + `go` commands | Multi-service repos, protobuf codegen |
| Python | `justfile` + `uv run` | Always (Python lacks a native task runner) |
| Terraform | `terraform` CLI | Multi-environment workspace management |

### Standard Task Interface

Every project should support these operations, regardless of how they're invoked:

```text
init    . install hooks, download deps
build   . compile / bundle
test    . run test suite
lint    . static analysis
fmt     . format code
check   . fmt + lint + test (quality gate)
run     . execute the project
record  . capture demo assets with teasr (when teasr.toml exists)
```

## Examples Convention

Projects that expose a library, SDK, or configurable tool include an `examples/` directory with self-contained, runnable examples.

### Structure

- `examples/basic/` -- simplest possible use case (always present when examples/ exists)
- `examples/<feature>/` -- named by feature being demonstrated (e.g., `agent/`, `streaming/`, `rag/`)
- `examples/<use-case>/` -- named by use case for config-driven tools (e.g., `petstore/`, `anthropic-messages/`)

### Entry Points by Language

| Language | Entry Point | Run Command |
|----------|-------------|-------------|
| Go | `main.go` | `go run ./examples/<name>/` |
| Rust | `main.rs` | `cargo run --example <name>` or standalone |
| Python | `main.py` | `uv run examples/<name>/main.py` |
| Node/TS | `index.ts` | `npx tsx examples/<name>/index.ts` |

Each example must:
1. Work with minimal dependencies and zero configuration
2. Be referenced from the README Quick Start via fsrc (see `write-readme`)
3. Include a doc comment at the top explaining prerequisites and how to run it

## Showcase & Demo Convention

Projects with a CLI or visual output include demo assets for the README.

| File | Purpose |
|------|---------|
| `teasr.toml` | Demo recording config (see `style-brand` for template and theme) |
| `showcase/demo.gif` | Hero demo animation (referenced in README at 80% width) |
| `showcase/demo.png` | Hero demo screenshot (fallback if no GIF) |
| `showcase/<feature>.png` | Feature-specific captures |

The `record` task invokes `teasr showme` which reads `teasr.toml` and outputs to `showcase/`. For projects recording their own CLI, build first:

```make
record: build
    teasr showme
```

## Spec Convention

Projects that expose or consume a formal API place specifications in `spec/`:

| Format | Extension | Example |
|--------|-----------|---------|
| OpenAPI | `.yaml` / `.json` | `spec/openapi.yaml` |
| Protocol Buffers | `.proto` | `spec/service.proto` |
| GraphQL | `.graphql` | `spec/schema.graphql` |
| JSON Schema | `.json` | `spec/config-schema.json` |

For multi-version APIs, use subdirectories: `spec/v1/`, `spec/v2/`.

## Python Config (`pyproject.toml`)
- `[tool.ruff]` line-length 100, select `["E","W","F","I","UP","B","SIM","RUF"]`
- `[tool.pytest.ini_options]` testpaths `["tests"]`, pythonpath `["src"]`

## CONTRIBUTING.md Template

Standard sections:
1. **Prerequisites** language runtime, build tools, GH_TOKEN
2. **Getting Started** `git clone` + language-specific init
3. **Development** language-specific check, test, fmt commands
4. **Commit Convention** conventional commits (Angular); see `ship` skill for AI-assisted authoring
5. **Pull Requests** fork, branch, PR
6. **Code Style** brief, language-specific

## License

Apache-2.0 for all repos. Exception: content-heavy sites (urmzd.com) may dual-license with CC BY-NC-ND 4.0 for content.

## Sub-Package Convention

Publishable workspace members (sub-crates, sub-packages) must include their own documentation files for registry compliance (crates.io, npm, PyPI).

| File | Source | When Required |
|------|--------|---------------|
| `LICENSE` | Copy of root `LICENSE` | Always (registries require per-package license) |
| `README.md` | Minimal: crate name, description, link to parent workspace | Always (registries display per-package README) |

### Minimal Sub-Package README Template

```markdown
# {crate-name}

{description from Cargo.toml / pyproject.toml / package.json}

Part of the [{workspace-name}]({repository-url}) workspace.

## License

[Apache-2.0](../../LICENSE)
```

Skip `examples/` workspace members -- they are not published independently.

## Documentation Philosophy

### Skills vs Docs

**Skills (`skills/<name>/SKILL.md`)** are executable agent instructions. They tell AI agents *how to do things*: follow conventions, run workflows, use tools. They are operational, imperative, and agent-consumable.

**Docs (`docs/`)** are project documentation. They capture *what was decided and why*: design proposals, how-to guides, operational runbooks, architecture descriptions, and plans. They serve humans and agents alike as reference material.

Both exist in every project. Neither replaces the other.

### File Placement

`scaffold-docs` owns the root-file allowlist, the `docs/` taxonomy (architecture,
adrs, rfcs, guides, reference, runbooks, plans) and the templates. Load it when
creating `docs/` or deciding where a document goes. Community health file
templates live in `community-health`.
