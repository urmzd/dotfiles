---
name: sync-ecosystem
description: >
  Audit a single repository against ecosystem conventions and sync findings back to
  chezmoi skills in the dotfiles repo. Use when onboarding a new repo, after a naming
  refactor, when terminology has drifted, or to ensure chezmoi skills stay current
  with a project's capabilities. Accepts a repo path as argument.
allowed-tools: Read Grep Glob Bash Edit Write Agent
user-invocable: true
license: Apache-2.0
metadata:
  title: Ecosystem Sync
  category: maintenance
  order: 30
---

# Ecosystem Sync

Audit one repository for consistency with the rest of the ecosystem, then sync any drift back into chezmoi-managed skills.

**Usage:** `/sync-ecosystem <repo-path>`

If no path is given, ask which repo to audit before proceeding.

## Principle

Ecosystem conventions evolve. This skill does not enumerate them inline — that list rots. Instead, it runs an **audit loop** that pulls the current rules from the skills that own each convention, then reports drift between the target repo and those rules.

## Audit Loop

### 1. Establish repo context

Read whatever identity and manifest files the repo has (README, AGENTS.md, llms.txt, language manifest). From these infer:

- **Name and description** the identity the rest of the ecosystem should agree with
- **Repo type** library, CLI, service, website, or something else — dictates which conventions apply
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
| CLI conventions | `cli-standards`, `build-cli` |

### 3. Check drift

Run generic drift checks against what you discovered:

- **File presence** does the repo have every artifact the owning skills require for this repo type?
- **Content currency** do listed commands, dependencies, and examples match the current manifest and code?
- **Cross-reference agreement** do name, description, install command, and version agree across docs and manifest?
- **Version discipline** does the latest git tag match the manifest version (or match the tagging scheme declared by `sync-release`)?
- **Terminology** does usage in the repo match the terms used in this ecosystem's other published skills and docs? Flag divergences; do not auto-rewrite.

### 4. Chezmoi coverage

Find the chezmoi source:

```sh
chezmoi source-path
```

For each skill the target repo exposes under `skills/` (if any), verify:

- A counterpart exists in `<chezmoi-source>/dot_agents/skills/`
- The counterpart's body matches the repo's current state (commands, file paths, feature list)
- Frontmatter is valid **name matches directory, description is specific and imperative, `allowed-tools` lists only what the skill uses, body is under ~500 lines**

Flag any skill present in the repo but missing or stale in chezmoi.

### 5. Report

```
## Ecosystem Audit — <repo-name>

### Repo Type
<library | CLI | service | website | other>

### Required Artifacts
- <artifact>: ✓ / ✗ (reason, with owning-skill reference)

### Drift
- <file>:<line> — <description of drift, with owning-skill reference>

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
| Missing artifact | Run the owning skill (`configure-ai`, `create-llms-txt`, etc.) against the repo |
| Content drift | Edit the offending file to match current state; propagate to dependents |
| Skill in repo but not in chezmoi | Copy skill dir into `<chezmoi-source>/dot_agents/skills/` |
| Stale chezmoi skill | Fix frontmatter or body in the chezmoi source |

After editing any chezmoi skill:

```sh
chezmoi apply
agentspec sync --fast
```

## Gotchas

- Edit skills in the chezmoi **source** directory. The deployed copy under `~/.agents/skills/` is overwritten on the next `chezmoi apply`.
- Only repos with user-facing agent capabilities need a `skills/` directory. Libraries and protocol specs do not.
- Don't auto-execute consolidation plans found in planning docs **flag them for user decision**.
- Report version/tag mismatches but do not bump versions automatically.
