---
name: sync-ecosystem
description: >
  Audit a repository for ecosystem consistency: AGENTS.md coverage, llms.txt presence,
  skill exposure, semver discipline, and cross-repo naming coherence. Sync findings back
  to chezmoi skills in the dotfiles repo. Use when onboarding a new repo, after a naming
  refactor, when terminology has drifted, or to ensure chezmoi skills stay current with
  a project's capabilities. Accepts a repo path as argument.
allowed-tools: Read Grep Glob Bash Edit Write Agent
user-invocable: true
license: Apache-2.0
metadata:
  title: Ecosystem Sync
  category: maintenance
  order: 30
---

# Ecosystem Sync

Audit a single repository for ecosystem consistency and synchronize findings into chezmoi skills.

**Usage:** `/sync-ecosystem <repo-path>`

If no path is given, ask the user which repo to audit before proceeding.

## Ecosystem Conventions

These rules apply to every repo in the ecosystem:

| Convention | Standard |
|------------|----------|
| AGENTS.md | Required for any repo that exposes tools, skills, or a public API |
| llms.txt | Required for every published package or CLI tool |
| Semver | Go and Python CLI tools must have git tags (`v0.x.x`); Rust uses Cargo.toml version |
| Terminology | "provider" = LLM/embedding backend; "adapter" = tool integration layer; "skill" = agentskills.io portable capability; "tool" = MCP executable function |
| Skills dir | Repos with AGENTS.md and user-facing skills should have a `skills/` directory |

## Audit Workflow

### Step 1 — Establish repo context

Read the following files if they exist:
- `README.md` — name, description, type (library / CLI / website / framework)
- `AGENTS.md` — current commands, architecture, skill links
- `llms.txt` — links and descriptions
- `Cargo.toml` / `go.mod` / `pyproject.toml` / `package.json` — package name, version, declared deps

Determine the repo type. Libraries (`gymnasia`, `streamsafe`, protocol specs) do not need a `skills/` directory but still need `llms.txt`.

### Step 2 — Required file checklist

| File | Required for | Check |
|------|-------------|-------|
| `AGENTS.md` | All repos with tools, APIs, or skills | Present and current |
| `llms.txt` | Published packages and CLI tools | Present; links valid |
| `skills/` | Repos with user-facing agent capabilities | Present if applicable |

### Step 3 — Terminology scan

Check for naming violations:

```sh
# "adapter" vs "provider" — flag if integration layer is called "provider"
grep -rn "provider" <repo>/src/ --include="*.rs" --include="*.go" --include="*.ts"
```

Flag any usage where:
- "provider" is used to describe a tool/host integration (should be "adapter")
- "skill", "tool", "agent", or "memory" is used in a non-standard way

### Step 4 — Semver / version discipline

```sh
# Check latest git tag
git -C <repo> describe --tags --abbrev=0 2>/dev/null || echo "no tags"

# Check declared version in manifest
grep -m1 '"version"\|^version' <repo>/package.json <repo>/Cargo.toml <repo>/pyproject.toml 2>/dev/null
```

Flag if: no tags exist for a CLI/library, or tag doesn't match manifest version.

### Step 5 — Chezmoi skills coverage

Find the chezmoi dotfiles repo:

```sh
chezmoi source-path
```

Compare what the repo exposes in `skills/` against what exists under `<chezmoi-source>/dot_agents/skills/`.

For each skill in `<repo>/skills/`:
- Does a counterpart exist in chezmoi?
- If yes, is it up to date with the repo's skill content?

### Step 6 — Validate existing chezmoi skill (if present)

Read `<chezmoi-source>/dot_agents/skills/<skill-name>/SKILL.md` and verify:

1. `name` matches directory name exactly (lowercase, hyphens only)
2. `description` is imperative, includes trigger keywords, under 1024 chars
3. `allowed-tools` lists only tools the skill actually uses
4. Body is under 500 lines
5. Any commands referenced still exist in the codebase

## Report Format

```
## Ecosystem Audit — <repo-name>

### Required Files
- AGENTS.md: ✓ / ✗ (reason)
- llms.txt: ✓ / ✗ (reason)
- skills/: ✓ / ✗ / N/A

### Terminology Issues
- <file>:<line> — description of violation

### Version Discipline
- Latest tag: <tag or "none">
- Manifest version: <version>
- Status: ✓ aligned / ✗ mismatch

### Chezmoi Skill Coverage
- <skill-name>: in repo ✓, in chezmoi ✓/✗, up to date ✓/✗

### Summary
X checks run. Y issues found.
```

## Fix Strategy

| Issue | Action |
|-------|--------|
| Missing AGENTS.md | Run `create-agentsmd` skill on the repo |
| Missing llms.txt | Run `create-llms-txt` skill on the repo |
| Terminology drift | Edit offending files; update dependents |
| Skill in repo but not chezmoi | Copy skill dir into `<chezmoi-source>/dot_agents/skills/` |
| Stale chezmoi skill | Fix frontmatter or body in chezmoi source |

After editing any chezmoi skill:

```sh
chezmoi apply
agentspec sync --fast
```

## Gotchas

- Edit skills in the chezmoi **source** directory, not the deployed `~/.agents/skills/`. Changes to the deployed copy will be overwritten on next `chezmoi apply`.
- Pure libraries and protocol specs don't need a `skills/` dir — only repos with user-facing agent capabilities do.
- Don't auto-execute consolidation plans found in planning docs — flag them for user decision.
- Version tags and manifest versions must match. If they differ, report the mismatch but don't bump versions automatically.
