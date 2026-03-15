---
name: llms-txt
description: llms.txt convention — provide LLM-friendly project summaries for AI discovery. Use when creating llms.txt files or making projects AI-discoverable.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
metadata:
  title: llms.txt
  category: ai
  order: 1
---

# llms.txt Convention

## What is llms.txt

A markdown file at project root that helps LLMs quickly understand what a project does, its key resources, and how to use it. Complements README (for humans) and AGENTS.md (for AI development context).

## Format

```markdown
# {Project Name}

> {One-paragraph summary with key context}

## Docs

- [README](https://github.com/urmzd/{repo}/blob/main/README.md): Installation, usage, and examples
- [AGENTS.md](https://github.com/urmzd/{repo}/blob/main/AGENTS.md): Architecture and development guide
- [CHANGELOG](https://github.com/urmzd/{repo}/blob/main/CHANGELOG.md): Version history

## API / Key Files

- [{key-file}](https://github.com/urmzd/{repo}/blob/main/{path}): {description}

## Optional

- [CONTRIBUTING](https://github.com/urmzd/{repo}/blob/main/CONTRIBUTING.md): How to contribute
- [Skill](https://github.com/urmzd/{repo}/blob/main/skills/{name}/SKILL.md): Agent skill
```

## When to Create

Every public repo should have `llms.txt` at root.

## Relationship to Other Files

| File | Purpose |
|------|---------|
| `llms.txt` | Discovery — what is this? where's the info? |
| `README.md` | Human docs — install, use, configure |
| `AGENTS.md` | AI dev context — architecture, commands, style |
| `SKILL.md` | Agent instructions — step-by-step guidance |
