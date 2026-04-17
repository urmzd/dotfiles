---
name: sync-docs
description: >
  Audit and synchronize project documentation. Detect staleness, fix drift, and keep
  cross-references consistent across whatever docs the project has. Delegates file-specific
  rules to the skills that own them. Use after feature changes, refactors, or when docs
  may be stale. Can be run as a scheduled agent or invoked manually.
allowed-tools: Read Grep Glob Bash Edit Write
user-invocable: true
metadata:
  title: Documentation Sync
  category: maintenance
  order: 20
---

# Documentation Sync

Audit whatever documentation the project has, fix drift, and keep cross-references consistent. This skill owns the **audit loop**, not the list of files.

## When to Use

- After implementing a new feature or significant refactor
- When docs haven't been updated in a while
- As a scheduled agent to catch drift
- Before releases to ensure docs match the code

## Principle

Do not enumerate required files here. Different projects carry different docs, and the authoritative rules for each doc type live in the skill that owns it. This skill's job is to:

1. Discover what docs the project actually has
2. Detect drift between docs and code (and between docs and each other)
3. Delegate file-specific fixes to the owning skill
4. Verify cross-references agree

## Audit Loop

### 1. Discover

Glob for documentation artifacts that exist in the repo. Do not assume any specific file is present. Common locations: repo root (`README.md`, `AGENTS.md`, `llms.txt`, community health files), `docs/`, `skills/`, language manifests.

### 2. Detect drift

Generic drift checks that apply to any project:

**Embedded source drift.** If any file uses `fsrc` markers, run `fsrc --verify` to detect drift. Update with `fsrc` if drift is found.

```sh
grep -rl 'fsrc src=' . | xargs fsrc --verify
```

**Command drift.** Extract build, test, lint, and install commands referenced in docs. Confirm they still match the native tooling declared in the manifest. Stale references to a removed runner (e.g. justfile after migration to native tools) is the most common failure mode.

**Dead links.** Extract URLs from docs and spot-check reachability. Internal links should resolve to files that still exist.

**Deleted references.** Grep docs for names of files, modules, or commands that no longer exist in the tree.

### 3. Delegate specifics

File-specific structural rules live in the owning skill. When a file looks stale or incomplete, open the relevant skill for the authoritative checklist rather than duplicating rules here:

| Artifact | Owning skill |
|----------|--------------|
| `README.md` | `write-readme` |
| `AGENTS.md` | `configure-ai` |
| `llms.txt` | `create-llms-txt` |
| Community health files, required layout | `check-project` |
| Language/build-system docs | `scaffold-<lang>` |

### 4. Cross-reference consistency

The same facts often appear in several docs. When they disagree, pick one source of truth and propagate. The README title/description is usually the source of truth for identity; the manifest is the source of truth for version and package name.

Facts to cross-check when more than one doc mentions them: project name, tagline/description, install command, quickstart command, primary build/test commands, license.

### 5. Fix or flag

- Fix drift that is unambiguous (fsrc refresh, stale command names, dead internal links)
- Flag drift that needs judgment (architectural changes, new features without docs, description rewrites)
- Report what was fixed and what needs human review

## CI Integration

Repos that use `fsrc` should verify it in CI so drift is caught at PR time rather than by this skill. See `setup-ci` for the workflow pattern.

## Scheduled Sync

When invoked on a schedule:

1. Run the audit loop above against whatever the repo contains
2. Auto-fix mechanical drift (fsrc, dead internal links, command renames)
3. Flag structural issues for the next human review
4. Emit a short summary **what was fixed / what needs attention**
