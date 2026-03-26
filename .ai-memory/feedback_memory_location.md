---
name: memory-at-project-root
description: AI memory must live at project root in .ai-memory/, not in tool-specific paths
type: feedback
---

Store AI memory per the [llmem standard](https://github.com/urmzd/llmem): project-level at `.ai-memory/`, global at `~/.config/ai-memory/`.

**Why:** Memory should be tool-agnostic. Any AI agent should be able to read/write it. Two levels keep project context separate from user preferences.

**How to apply:** Use `.ai-memory/` at repo root for project memory, `~/.config/ai-memory/` for global. Never use tool-locked paths like `~/.claude/projects/*/memory/`.
