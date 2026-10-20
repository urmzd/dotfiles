---
name: align-readmes
description: >
  Audit and converge README.md across every local urmzd/* checkout so the fleet
  reads as one product: skip archived repos, flag renamed repos and stale
  identities, score each README against write-readme, then fix in priority
  order. Use when the user asks to consolidate, unify, standardize, or audit
  READMEs across repos, or after a rename wave. Do NOT use for a single repo's
  README (use write-readme), prose cleanup alone (use clean-docs), or whole-repo
  convention drift (use sync-ecosystem).
allowed-tools: Read, Grep, Glob, Edit, Bash(git *), Bash(gh *), Bash(bash *)
user-invocable: true
license: Apache-2.0
metadata:
  title: Align READMEs
  category: maintenance
  order: 31
---

# Align READMEs

One fleet, one voice. This skill owns the **cross-repo loop**. It does not own README rules: those live in `write-readme` (structure) and `clean-docs` (prose). Never restate them here.

**Usage:** `/align-readmes [root]` (default root: `~/github`)

## 1. Triage before touching anything

Run the bundled audit. It is read-only.

```sh
bash "${CLAUDE_SKILL_DIR:-$HOME/.agents/skills/align-readmes}/scripts/audit-readmes.sh" ~/github
```

Act on the `status` and `identity` columns first:

| Value | Meaning | Action |
|-------|---------|--------|
| `ARCHIVED` | Read-only on GitHub | **Skip.** Never edit. List it in the report so the user can delete the local checkout. |
| `MISSING` | Remote repo deleted or inaccessible | Skip. Ask the user. |
| `no-remote` | Local-only directory | Skip unless the user names it. |
| `dir-is:<name>` | Repo was renamed, folder was not | Use `<name>` in every README edit. Do not rename the folder without asking. |
| `stale-remote:<o/r>` | Remote URL predates a rename | Report `git remote set-url origin` fix. Do not run it unasked. |

Also verify against GitHub, not memory: renames happen in waves and recall goes stale.

```sh
gh repo list urmzd --limit 300 --json name,isArchived --jq '.[] | select(.isArchived) | .name'
```

## 2. Score the active set

Remaining columns map to `write-readme` rules:

| Column | Rule owner | Pass |
|--------|-----------|------|
| `hdr` | write-readme: Centered Header | `3` |
| `badges` | write-readme: Badges | `1` to `4` |
| `em_dash` | clean-docs | `0` |
| `tree` | write-readme: No Project Structure | `0` |
| `toc_needed` | write-readme: ToC (300+ lines) | `ok` or `-` |
| `quick_start` | write-readme: Quick Start | `ok` |
| `skill_2nd` | write-readme: Agent Skill position | `ok`, or `no` when the repo has no `skills/` |
| `license_last` | write-readme: Section Order | `ok` |

The script is a fast filter, not the verdict. Read each failing README before editing.

**Exempt:** the `urmzd` profile repo is a GitHub profile page, not a project README. Skip header, Quick Start, and section-order rules for it.

## 3. Unify, do not merely comply

Compliance per repo is not enough. Check the fleet for **shared identity**:

- **Names.** Every cross-repo link and mention uses the current GitHub name (`gh repo view` resolves redirects). Grep all READMEs for each old name from step 1.
- **Shared phrasing.** Sections that exist in many repos (Agent Skill, License, Installation via `install.sh`) use the exact template wording from `write-readme`. Divergent copies are drift.
- **Related section.** When repos form a family (agent platform, release tooling), each README links its siblings with the same one-line descriptions. Take the description from `gh repo view --json description`, so GitHub stays the single source.
- **Descriptions.** The README one-liner matches the GitHub repo description. Report mismatches; fix with `update-repo-meta` only when the user approves.

Do not create a shared README include file or a central docs repo. Each README must stand alone on GitHub.

## 4. Fix in priority order

Fix one repo per commit. Order:

1. Stale names and broken cross-links (users hit dead links)
2. Missing Quick Start or header (first-impression failures)
3. Directory trees, misplaced Agent Skill, section order
4. Em dashes and prose (run `clean-docs`)

For each repo, apply `write-readme`, then run `fsrc` if the README has markers. Commit with `ship` as `docs(readme): align with fleet standard`. Do not push unless asked.

## 5. Report

```text
## README Alignment: <date>

Skipped (archived): <repos>
Identity drift: <dir -> github name>, <stale remotes>

| Repo | Failing checks | Fixed |
|------|----------------|-------|

Fleet issues: <cross-repo naming, phrasing, Related-section gaps>
```

## Gotchas

- `gh repo view <old-name>` silently returns the new repo. Compare `nameWithOwner` to detect renames; the script does this.
- Edit this skill in the chezmoi source (`dot_agents/skills/align-readmes`), then `chezmoi apply`. Deployed copies are overwritten.
- If a rule in the audit table changes, change it in `write-readme` first, then update the script check. The script follows the skill, never the reverse.
