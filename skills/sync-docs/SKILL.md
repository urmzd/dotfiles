---
name: sync-docs
description: >
  Audit and synchronize project documentation — README, AGENTS.md, llms.txt, docs/,
  and embed-src markers. Use after feature changes, refactors, or when docs may be stale.
  Can be run as a scheduled agent or invoked manually.
allowed-tools: Read Grep Glob Bash Edit Write
user-invocable: true
metadata:
  title: Documentation Sync
  category: maintenance
  order: 20
---

# Documentation Sync

Audit project documentation for consistency, staleness, and completeness. Fix issues found.

## When to Use

- After implementing a new feature or significant refactor
- When docs haven't been updated in a while
- As a scheduled agent to catch drift
- Before releases to ensure docs match the code

## Audit Checklist

### 1. embed-src Markers

Run `embed-src --verify` on all files with markers to detect drift:

```sh
# Find all files with embed-src markers
grep -rl 'embed-src src=' . --include='*.md' | xargs embed-src --verify
```

If any markers are stale, run `embed-src` to update them:

```sh
grep -rl 'embed-src src=' . --include='*.md' | xargs embed-src
```

### 2. README Completeness

Check the README against `write-readme` standards:

| Section | Required | Check |
|---------|----------|-------|
| Centered header | Always | Title, description, 3 links |
| CI badge | Always | Points to valid workflow |
| Features | Always | 3-8 bullet points |
| Installation | Always | install.sh for CLIs, package manager for libs |
| Quick Start | Always | Minimal path from install to first result |
| Usage / CLI Reference | If CLI | Commands, flags, examples |
| Configuration | If configurable | Config file format, env vars |
| Architecture | If complex | Brief summary + link to `docs/architecture.md` |
| Agent Skill | If skills exist | Link to `skills/` |
| License | Always | Apache-2.0 |

### 3. AGENTS.md Currency

Verify AGENTS.md reflects the current state:

- Commands section matches actual build/test/lint commands (native tools, not stale justfile references)
- Architecture overview matches current code structure
- No references to deleted files, renamed modules, or removed features

### 4. llms.txt

Verify `llms.txt` exists and links are valid:

```sh
# Check all URLs in llms.txt are reachable
grep -oP 'https?://\S+' llms.txt | xargs -I{} curl -sI {} | grep -E '^HTTP'
```

### 5. docs/ Directory

Check docs are current:

| File | Check |
|------|-------|
| `docs/architecture.md` | Matches current system design |
| `docs/guides/*.md` | Procedures still work |
| `docs/runbooks/*.md` | Commands and URLs are valid |
| `docs/rfcs/*.md` | Status fields are accurate |

### 6. Cross-Reference Consistency

Ensure these files agree on:

- **Project name** — README title, AGENTS.md identity, llms.txt title, package.json/Cargo.toml/pyproject.toml name
- **Description** — README subtitle, AGENTS.md description, llms.txt description, repo description
- **Commands** — README Quick Start, AGENTS.md commands, CONTRIBUTING.md development section
- **Installation** — README install, llms.txt install link

## Fix Strategy

1. **embed-src drift** — run embed-src to update markers
2. **Missing sections** — add them following `write-readme` conventions
3. **Stale commands** — update to match native build system (see `scaffold-*` skills)
4. **Dead links** — remove or update
5. **Description mismatch** — use README as source of truth, propagate to other files

## CI Integration

Add embed-src verification to CI to catch drift early:

```yaml
# In ci.yml, before other jobs
embed:
  name: Verify Embedded Sources
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: urmzd/embed-src@v3
      with:
        commit-dry: "true"
        commit-push: "false"
    - name: Check for drift
      run: git diff --exit-code
```

## Scheduled Sync

This skill can be run on a schedule to keep docs fresh. When invoked:

1. Run the full audit checklist above
2. Fix any embed-src drift automatically
3. Flag sections that need human review (architecture changes, new features without docs)
4. Report a summary of what was fixed and what needs attention
