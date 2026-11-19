---
name: scaffold-docs
description: >
  Owns where documentation lives: the root-file allowlist (README, CONTRIBUTING,
  USAGE, CODEOWNERS and the other GitHub and tooling files) and the docs/ taxonomy
  (architecture, adrs, rfcs, guides, reference, runbooks, plans) with templates
  for each kind. Includes the Zensical publishing setup for core services.
  Scaffolds docs/ for a new repo, moves misplaced docs into it,
  and retires stale ones (finished plans, superseded decisions, duplicated
  upgrade notes). Use when creating docs/, adding an ADR, RFC, guide or runbook,
  asked to "clean up stale docs", "organize docs", or when a doc sits at the repo
  root or in the wrong docs/ folder. Do NOT use for prose cleanup (use
  clean-docs), drift between docs and code (use sync-docs), README structure
  (use write-readme) or AGENTS.md (use configure-ai).
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(git *), Bash(rg *)
user-invocable: true
metadata:
  title: Documentation Layout
  category: development
---

# Documentation Layout

This skill is the single owner of **where** a doc lives. Other skills link here
instead of restating the layout.

## Root allowlist

Only these files sit at the repo root. Everything else that is prose goes in `docs/`.

| File | Why it is at root |
|------|-------------------|
| `README.md` | GitHub renders it on the repo page |
| `CONTRIBUTING.md` | GitHub links it from issues and PRs |
| `USAGE.md` | Optional. Long-form usage when it would swamp the README |
| `CODEOWNERS` | GitHub reads it from root, `.github/` or `docs/`; keep it at root or `.github/` |
| `LICENSE`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md` | GitHub community health files |
| `NOTICE`, `LICENSING.md` | Legal files that `LICENSE` or package metadata names |
| `CHANGELOG.md` | Written by the release tool (sr) |
| `AGENTS.md`, `CLAUDE.md` | Read from root by AI tools (see `configure-ai`) |
| `llms.txt` | Spec requires root (see `create-llms-txt`) |

Also allowed outside `docs/`:

- A `README.md` that explains its own directory (`examples/README.md`, `themes/README.md`).
- Markdown that is program input, not documentation: embedded prompts, `.agent.md` definitions, test fixtures, `skills/<name>/SKILL.md`.
- `.github/` templates (PR template, issue forms).

## Generated output stays out of docs/

`docs/` holds prose and the images that prose embeds. Anything a command
produces lives next to the code that produces it.

| Piece | Location |
|-------|----------|
| Benchmark or eval harness | Where the language puts it (`benches/`, `crates/*/benches/`, `scripts/`, `evals/`) |
| Benchmark or eval results (JSON, CSV, logs) | `benchmarks/results/` (or `evals/results/`) at the repo root |
| Report on those results (method, provenance, tables) | `docs/reference/benchmarks.md`, tables embedded from the results with fsrc |
| Images, screenshots, rendered diagrams embedded in docs | `docs/assets/`, with a diagram's source (`.d2`, `.mmd`) beside its render |
| Demo captures | `showcase/` (owned by teasr) |

Anything else at root moves: `ARCHITECTURE.md` to `docs/architecture/overview.md`,
`ROADMAP.md` to `docs/plans/roadmap.md` (or GitHub Issues), `MIGRATION.md` or
`UPGRADING.md` to `docs/guides/upgrading.md`, `INSTALL.md` into the README.

## docs/ taxonomy

Create a folder only when there is a document for it. Never scaffold empty folders.

| Folder | Holds | Lifecycle | File name |
|--------|-------|-----------|-----------|
| `docs/architecture/` | How the system is built now: components, data flow, boundaries, limitations | Living. Edit in the same PR as the code change | `overview.md`, `<topic>.md` |
| `docs/adrs/` | One decision, its context and consequences | Immutable once accepted. Change by a new ADR that supersedes it | `NNNN-<slug>.md` |
| `docs/rfcs/` | A proposal before it is built, open for discussion | `Draft` to `Accepted`, `Rejected` or `Implemented`. When implemented, the built design moves to `architecture/` and the RFC keeps its status line | `NNNN-<slug>.md` |
| `docs/guides/` | Task-oriented how-tos: set up, upgrade, migrate, integrate | Living. One task per guide | `<task>.md` (`upgrading.md`) |
| `docs/reference/` | Lookup facts: config keys, event types, CLI flags, per-connector capabilities | Living. Prefer generating from code | `<subject>.md` |
| `docs/runbooks/` | Operational steps for an alert or incident | Living. Owned by whoever is on call | `<alert-or-task>.md` |
| `docs/plans/` | Time-bound work plans, roadmaps, checklists | Delete when done. Git history keeps them | `<yyyy-mm>-<slug>.md`, `roadmap.md` |
| `docs/assets/` | Images and diagram sources embedded by docs. No prose | Delete when nothing links them | any |
| `docs/internal/` | Private repos only: notes excluded from any public export (pitch, strategy, named accounts) | Living. Never link to it from publishable docs | `<topic>.md` |

A `docs/design/` folder of proposals becomes `docs/rfcs/`. A design doc that
describes what is built is architecture.

`docs/README.md` is the documentation home. Introduce the project and link to the first
task. List each public document with a one-line purpose and include the number
and status of each ADR and RFC. For a large collection, move the inventory to
`docs/catalog.md` and link it from the home page.

Numbering for ADRs and RFCs is four digits, starting at `0001`, never reused.

## Templates

Copy from `assets/` in this skill. Fill every section or delete it; never leave placeholder text.

| Kind | Template |
|------|----------|
| `docs/README.md` index | [assets/docs-index.md](assets/docs-index.md) |
| ADR | [assets/adr.md](assets/adr.md) |
| RFC | [assets/rfc.md](assets/rfc.md) |
| Guide | [assets/guide.md](assets/guide.md) |
| Runbook | [assets/runbook.md](assets/runbook.md) |
| Plan | [assets/plan.md](assets/plan.md) |
| Core service site | [assets/zensical.toml](assets/zensical.toml) |

## Core service documentation sites

Each service keeps its source in `docs/` and its `zensical.toml` at the repository
root. Copy the template, set the service name, repository URL and
`https://docs.urmzd.com/<repo>/` with the trailing slash. Set the navigation
paths to pages that exist. Start at `README.md`, then guide the reader through
a runnable example with expected output, the concepts it uses and the reference
for looking things up. Keep historical proposals in the inventory. Navigation
controls what readers see in the menu. The generator also builds unlisted
pages, so exclude private material from the published source and output.

Use relative Markdown links inside `docs/` so the same page works on GitHub and
under the service URL. For files outside `docs/`, link to their GitHub `blob`
or `tree` URL with the correct ref, using a commit permalink for a
version-specific example. A link such as `../../cmd/server/main.go` would
escape the published service directory. Keep a screenshot in `docs/assets/`
when it should appear inline. Ignore generated `/site/` and `/.cache/` in Git.

From the service repository root, build the same pinned version used by the
hub. Start the local server to inspect the rendered pages.

```sh
uvx --from zensical==0.1.2 zensical build --strict
uvx --from zensical==0.1.2 zensical serve
```

Open the URL printed by the server. Follow the first task, a reference link and
a source-code link. Check the home page and a nested page at phone and desktop
widths. To check the production subpath, serve the assembled hub locally and
open `/<repo>/`. Confirm the stylesheet, images, search and navigation all
resolve beneath that prefix.

One dedicated GitHub Pages repository serves `docs.urmzd.com`. Its manifest
selects a reviewed full commit SHA for each service. The hub checks out those
commits, builds each site and assembles the generated directories at their
repository slugs into one Pages artifact. A service update reaches the host
through a reviewed pin change in the hub. Keep the domain and Pages deployment
workflow in that repository.

## Workflow

### 1. Audit

```bash
checker="${CLAUDE_SKILL_DIR:-$HOME/.agents/skills/scaffold-docs}/scripts/check-docs-layout.sh"
"$checker" .
```

From the chezmoi source tree the script is
`dot_agents/skills/scaffold-docs/scripts/executable_check-docs-layout.sh`.
It reports stray root docs, unknown `docs/` folders, a missing `docs/README.md`,
and ADR or RFC files that break the naming rule. Exit 1 means findings.

### 2. Classify each doc

Read it and ask what a reader uses it for. A file can mix kinds; split it.

| Signal in the doc | Kind |
|-------------------|------|
| "We decided", alternatives considered | ADR |
| "We propose", open questions, not yet built | RFC |
| Present-tense description of how it works | architecture |
| Numbered steps toward a goal | guide (or runbook if triggered by an alert) |
| Tables of names, types, flags | reference |
| Dates, milestones, checkboxes | plan |
| Before/after names, "upgrading", "migrating" | guide (`upgrading.md`, newest change first) |

### 3. Retire stale docs

- **Finished plan:** delete it.
- **Implemented RFC:** set status `Implemented`, link the architecture doc, stop editing it.
- **Superseded ADR:** set `Superseded by NNNN`; never delete.
- **Duplicated content** (two upgrade notes, a design restated in README): keep one owner, link to it from the others.
- **References to code that no longer exists:** fix them (run `sync-docs`). A table that deliberately maps removed names to new ones is not stale.

### 4. Move without breaking links

1. Before moving a file, search for inbound links in this repo **and** sibling
   repos, including vendored copies and submodules:
   ```bash
   rg -n 'docs/<old-path>|<old-file>\.md' .. --glob '!**/node_modules/**' --glob '!**/CHANGELOG.md'
   ```
2. If another repo links the path or one of its `#anchors`, leave the file where
   it is or keep the heading and replace its body with a one-line link to the new
   home. Do not edit another repo without asking.
3. Use `git mv` so history follows the file.
4. Update every in-repo link: README docs table, AGENTS.md, llms.txt `## Docs`,
   CONTRIBUTING, code comments that cite a doc path.
5. Update `docs/README.md`.
6. Run `clean-docs` on files you rewrote.

## Rules

- One owner per fact. Link instead of copying between README, AGENTS.md and docs.
- Docs describe the current state. History belongs in CHANGELOG, ADRs and git.
- Never invent rationale for an ADR. Write one only from a decision recorded in a PR, commit body, issue or existing doc, and cite it.
- `CHANGELOG.md` entries keep the names they were written with. Do not rewrite them.
