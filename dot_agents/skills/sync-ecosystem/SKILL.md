---
name: sync-ecosystem
description: >
  Audit one repository against ecosystem conventions (naming, capabilities, terminology,
  doc coverage, version discipline, canonical skill coverage) and emit a read-only drift
  report. Use when onboarding a repo, auditing convention drift, or checking ecosystem
  consistency after a refactor. This skill only reports; it never edits the target repo or
  the skill store. Do NOT use for applying fixes back into the chezmoi-managed canonical
  store; use sync-ecosystem-to-chezmoi for that.
allowed-tools: Read, Grep, Glob, Bash(git *), Bash(chezmoi *)
user-invocable: true
license: Apache-2.0
metadata:
  title: Ecosystem Sync
  category: maintenance
  order: 30
---

# Ecosystem Sync

Audit one repository for consistency with the rest of the ecosystem and emit a drift report. To push the report back into the canonical skill store, chain with sync-ecosystem-to-chezmoi (or your equivalent).

**Usage:** `/sync-ecosystem <repo-path>`

If no path is given, ask which repo to audit before proceeding.

## Principle

Ecosystem conventions evolve. This skill does not enumerate them inline -- that list rots. Instead, it runs an **audit loop** that pulls the current rules from the skills that own each convention, then reports drift between the target repo and those rules.

## Audit Loop

### 1. Establish repo context

Read whatever identity and manifest files the repo has (README, AGENTS.md, llms.txt, language manifest). From these infer:

- **Name and description** the identity the rest of the ecosystem should agree with
- **Repo type** library, CLI, service, website, or something else -- dictates which conventions apply
- **Language and build system** dictates which `scaffold-<lang>` skill to consult

Don't assume any specific file is present. Absence of a file is itself a finding.

### 2. Pull current conventions

For each convention category, consult the owning skill rather than enumerating rules here:

| Category | Owning skill |
|----------|--------------|
| Required project layout | `check-project` |
| Community-health files (CODE_OF_CONDUCT, SECURITY, issue forms, PR template) | `community-health` |
| README structure | `write-readme` |
| AGENTS.md structure | `configure-ai` |
| llms.txt structure | `create-llms-txt` |
| CI/release workflow | `setup-ci`, `sync-release` |
| Language-specific scaffold | `scaffold-<lang>` |
| CLI conventions | `build-cli` |
| Doc-drift (fsrc, command renames, dead links) | `sync-docs` (delegate, do not re-implement) |

### 3. Check drift

Run generic drift checks against what you discovered:

- **File presence** does the repo have every artifact the owning skills require for this repo type?
- **Content currency** do listed commands, dependencies, and examples match the current manifest and code?
- **Cross-reference agreement** do name, description, install command, and version agree across docs and manifest?
- **Version discipline** does the latest git tag match the manifest version (or match the tagging scheme declared by `sync-release`)?
- **Terminology** does usage in the repo match the terms used in this ecosystem's other published skills and docs? Flag divergences; do not auto-rewrite.
- **Doc subset** for the documentation-specific portion of the audit (fsrc drift, dead internal links, stale commands), invoke `sync-docs` instead of re-implementing the checks.

### 4. Canonical skill coverage

Locate the canonical skill source (chezmoi users: `chezmoi source-path`; others: `${CLAUDE_SKILL_DIR:-$HOME/.agents/skills}`):

```sh
chezmoi source-path
```

For each skill the target repo exposes under `skills/` (if any), verify:

- A counterpart exists in the canonical skill source (`<source>/dot_agents/skills/` for chezmoi, or `${CLAUDE_SKILL_DIR:-$HOME/.agents/skills}/`)
- The counterpart's body matches the repo's current state (commands, file paths, feature list)
- Frontmatter is valid **name matches directory, description is specific and imperative, `allowed-tools` lists only what the skill uses, body is under ~500 lines**

Flag any skill present in the repo but missing or stale in the canonical store.

### 5. Report

```text
## Ecosystem Audit -- <repo-name>

### Repo Type
<library | CLI | service | website | other>

### Required Artifacts
- <artifact>: ✓ / ✗ (reason, with owning-skill reference)

### Drift
- <file>:<line> -- <description of drift, with owning-skill reference>

### Version Discipline
- Latest tag: <tag or "none">
- Manifest version: <version>
- Status: ✓ aligned / ✗ mismatch

### Canonical Skill Coverage
- <skill-name>: in repo ✓, in canonical store ✓/✗, up to date ✓/✗

### Summary
X checks run. Y issues found.
```

## Fix Strategy

| Issue | Action |
|-------|--------|
| Missing artifact | Run the owning skill (`configure-ai`, `create-llms-txt`, etc.) against the repo |
| Content drift | Edit the offending file to match current state; propagate to dependents |
| Skill in repo but not in canonical store | Copy skill dir into the canonical source (`<chezmoi-source>/dot_agents/skills/` or equivalent) |
| Stale canonical skill | Fix frontmatter or body in the canonical source (not the deployed copy) |
| Drift report needs to push back to chezmoi | Hand off to `sync-ecosystem-to-chezmoi` |

After editing any canonical skill (chezmoi users only):

```sh
chezmoi apply
agentspec sync --fast
```

## Gotchas

- Edit skills in the **canonical source** (for chezmoi users, the chezmoi source dir). Deployed copies under `${CLAUDE_SKILL_DIR:-$HOME/.agents/skills}/` are overwritten on the next sync.
- Only repos with user-facing agent capabilities need a `skills/` directory. Libraries and protocol specs do not.
- Don't auto-execute consolidation plans found in planning docs -- **flag them for user decision**.
- Report version/tag mismatches but do not bump versions automatically.
- For the doc-specific drift checks (fsrc verification, command renames, dead internal links), defer to `sync-docs` rather than duplicating logic here.
