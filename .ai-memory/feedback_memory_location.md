---
name: memory-at-project-root
description: AI memory must live at project root in .ai-memory/, not in tool-specific paths
type: feedback
---

Store all AI memory in `.ai-memory/` at the project root — never in tool-specific paths like `~/.claude/`.

**Why:** Memory should be tool-agnostic and project-specific. Any AI agent should be able to read/write it. Consistency across all projects.

**How to apply:** Always use `.ai-memory/` at repo root for memory files. Never use `~/.claude/projects/*/memory/` or similar tool-locked paths.
