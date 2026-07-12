---
name: sync-docs
description: >
  Audit and synchronize project documentation. Enforce clean prose, no em dashes,
  evidence-backed accuracy, current embedded examples, command drift checks,
  and cross-reference consistency. Use after feature changes, refactors, stale
  docs, README/AGENTS/llms.txt edits, or when the user asks to clean up docs.
  Delegates file-specific structure to owning skills.
allowed-tools: Read, Grep, Glob, Bash(git *), Bash(fsrc *), Bash(agentspec *), Bash(jq *), Edit, Write
user-invocable: true
metadata:
  title: Documentation Sync
  category: maintenance
  order: 20
---

# Documentation Sync

Audit whatever documentation the project has, fix drift, and keep cross-references consistent. This skill owns the **audit loop**, not the list of files.

For repos with this skill installed, start with the bundled hygiene gate:

```sh
checker="${CLAUDE_SKILL_DIR:-$HOME/.agents/skills}/sync-docs/scripts/check-doc-hygiene.sh"
"$checker" .
```

If running from a chezmoi source tree before `chezmoi apply`, use the source path:

```sh
dot_agents/skills/sync-docs/scripts/executable_check-doc-hygiene.sh .
```

## When to Use

- After implementing a new feature or significant refactor
- When docs haven't been updated in a while
- When the user asks for documentation to be clean, precise, accurate, or up to date
- When adding or editing `dot_agents/skills/*/SKILL.md` or `dot_agents/agents/*.md`
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

**Text hygiene.** Tracked text, comments, help output, and docs must not contain em dashes. Use periods, colons, commas, or indexed bullets instead. Check with:

```sh
rg -n "$(printf '\\342\\200\\224')" .
```

**Evidence-backed accuracy.** Every behavior claim, command, install step, and tool name must be checked against the current repo, manifest, CLI help, or authoritative source before editing. If the evidence is missing, flag it instead of guessing.

**Embedded source drift.** If any file uses real `fsrc` markers, run `fsrc run --verify` to detect drift. Update with `fsrc run` if drift is found.

```sh
rg -l '<!--[[:space:]]*fsrc[[:space:]]+src=' . -g '*.md' -g '*.mdx' -g '*.txt' | xargs fsrc run --verify
```

**Command drift.** Extract build, test, lint, and install commands referenced in docs. Confirm they still match the native tooling declared in the manifest. Stale references to a removed runner (e.g. justfile after migration to native tools) is the most common failure mode.

**Dead links.** Extract URLs from docs and spot-check reachability. Internal links should resolve to files that still exist.

**Deleted references.** Grep docs for names of files, modules, or commands that no longer exist in the tree.

**Agent resource drift.** If the repo has `dot_agents/`, validate every skill and agent, then confirm local source resources are managed by agentspec:

```sh
for file_path in dot_agents/skills/*/SKILL.md dot_agents/agents/*.md; do
  agentspec manage validate "$file_path"
done
agentspec manage add "$(pwd)/dot_agents" --all-tools
agentspec status
# If local shared-store resources are still unmanaged, adopt them by name:
# agentspec manage add <name> --all-tools
for name in $(find dot_agents/skills -mindepth 2 -maxdepth 2 -name SKILL.md | sed 's#dot_agents/skills/##; s#/SKILL.md##'); do
  agentspec manage verify --accept --name "$name"
done
for name in $(find dot_agents/agents -maxdepth 1 -name '*.md' | sed 's#dot_agents/agents/##; s#.md$##'); do
  agentspec manage verify --accept --name "$name"
done
agentspec sync --fast
```

### 3. Delegate specifics

File-specific structural rules live in the owning skill. When a file looks stale or incomplete, open the relevant skill for the authoritative checklist rather than duplicating rules here:

| Artifact | Owning skill |
|----------|--------------|
| General documentation cleanup | `clean-docs` |
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
