---
name: memory
description: Persistent learning from user notes, comments, coding style, capabilities, and questions. Use to build and maintain an evolving understanding of the user's preferences and patterns across conversations.
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: Memory
  category: ai
  order: 2
---

# Memory

## Purpose

Build a persistent, evolving understanding of the user by observing their notes, comments, coding style, capabilities, and questions. Memory turns one-off corrections into durable knowledge that improves every future conversation.

## Storage

All memory lives at the **project root** in `.ai-memory/`. This is tool-agnostic — any AI agent (Claude Code, Codex, Gemini, Copilot, Cursor) can read and write to it.

### Directory layout

```
.ai-memory/
├── MEMORY.md              # Index — one-line pointers to each memory file
├── user_<topic>.md        # Who the user is, their expertise, preferences
├── feedback_<topic>.md    # Corrections and validated approaches
├── project_<topic>.md     # Non-obvious project context and decisions
└── reference_<topic>.md   # Pointers to external resources
```

### Memory file format

Each file uses YAML frontmatter:

```markdown
---
name: <short-identifier>
description: <one-line summary — used to judge relevance>
type: <user | feedback | project | reference>
---

<content>
```

- **feedback** and **project** types should include `**Why:**` and `**How to apply:**` lines after the main statement
- Convert relative dates to absolute when saving (e.g., "Thursday" → "2026-03-05")

### Index format (MEMORY.md)

One line per memory, under 150 characters:

```markdown
- [Title](file.md) — one-line hook
```

Keep the index under 200 lines. It should be loaded into context at conversation start.

### Memory types

| Type | When | Example |
|------|------|---------|
| `user` | Learn about role, expertise, preferences | "Deep Rust expertise, new to React" |
| `feedback` | Correction or validated approach | "Never mock the database in integration tests" |
| `project` | Non-obvious project context | "Auth rewrite driven by compliance, not tech debt" |
| `reference` | External resource pointers | "Pipeline bugs tracked in Linear project INGEST" |

## What to Learn From

### Code & Commits
- **Naming patterns** — variable/function/file naming conventions the user consistently uses
- **Architecture choices** — preferred patterns (flat vs nested modules, error handling style, abstraction level)
- **Language idioms** — which language features they favor or avoid
- **Commit style** — message format, scope conventions, granularity

### Comments & Notes
- **TODO/FIXME patterns** — what the user flags for future work reveals priorities
- **Inline comments** — what they explain vs what they consider self-evident
- **PR descriptions** — how they frame changes reveals what they value (correctness, performance, simplicity)

### Questions & Corrections
- **Questions asked** — reveal knowledge boundaries and areas of active learning
- **Corrections given** — strongest signal; always persist immediately
- **Approaches accepted without comment** — validated patterns worth remembering

### Capabilities & Expertise
- **Languages/tools used fluently** — adjust explanation depth accordingly
- **Areas where they ask for help** — provide more scaffolding here
- **Domain knowledge** — business context, industry terms, system understanding

## Rules

1. **Project root only** — always use `.ai-memory/` at the repo root, never tool-specific paths
2. **Observe before saving** — don't save after one occurrence; wait for a pattern or explicit instruction
3. **Save corrections immediately** — if the user says "don't do X", persist it now
4. **Include why** — a rule without rationale can't be applied to edge cases
5. **Update, don't duplicate** — check existing memories before creating new ones
6. **Verify before acting on memory** — memory is a snapshot; current code is truth
7. **Respect privacy** — never save personal information unrelated to the work
8. **Prune stale memories** — if a memory contradicts current code or user behavior, update or remove it

## What NOT to Save

- Code patterns visible in the codebase (just read the code)
- Git history (use `git log`)
- Ephemeral task state (use a task tracker)
- Anything already documented in project root files (CLAUDE.md, AGENTS.md, etc.)
- Debugging solutions (the fix is in the code; the commit message has context)

## Anti-Patterns

- Using tool-specific memory paths (`~/.claude/`, `~/.copilot/`, etc.)
- Over-indexing on a single instance as a permanent preference
- Saving a memory and never verifying it against current state
- Storing memory content directly in the index instead of separate files
- Creating memories that duplicate what the codebase already expresses
