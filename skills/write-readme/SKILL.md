---
name: write-readme
description: README structure — centered header, badges, demos, section order, Agent Skill section, and llms.txt. Use when creating or updating any project README.
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: README Standards
  category: visual
  order: 1
---

# README Standards

## Centered Header Template

Every README starts with a centered header block:

```html
<p align="center">
  <h1 align="center">{Display Name}</h1>
  <p align="center">
    {One-line description}
    <br /><br />
    <a href="...releases">Download</a>
    &middot;
    <a href="...issues">Report Bug</a>
    &middot;
    <a href="{url}">{Third Link}</a>
  </p>
</p>
```

- Link 1: "Install" for libraries (Go `go get`, Python `uv add`), "Download" for binaries
- Link 2: "Report Bug" (always links to `/issues`)
- Link 3: contextual — Go Docs, GitHub Action, PyPI, Crates.io, Experiments, etc.

## CI Badges

Centered, immediately below header:

```html
<p align="center">
  <a href="...ci.yml"><img src="...badge.svg" alt="CI"></a>
</p>
```

## Demo Image

Below badges, 80% width:

```html
<p align="center">
  <img src="assets/demo.png" alt="Demo" width="80%">
</p>
```

## Output Gallery

For projects with multiple visual outputs (resume-generator pattern — 3-col, 30% width):

```html
<p align="center">
  <img src="..." width="30%"> &nbsp; <img src="..." width="30%"> &nbsp; <img src="..." width="30%">
</p>
<p align="center"><em>Label 1 &middot; Label 2 &middot; Label 3</em></p>
```

## Standard Section Order

Features → Install → Quick Start → Usage/CLI Reference → Configuration → API → Agent Skill → Related → License

## No Project Structure

READMEs must NOT include directory trees, file tables, or "Key Directories" sections. Project structure is discoverable via `tree` and `ripgrep`/`ag` — writing it out is duplicative and goes stale. AGENTS.md handles structural context for AI agents.

## Section Naming

Always "Quick Start" (never "Quickstart" or "Getting Started").

## Agent Skill Section

Every repo with a skill includes:

```markdown
## Agent Skill

This repo's conventions are available as portable agent skills in [`skills/`](skills/).
```

## llms.txt

Every repo should have `llms.txt` at root per the [llms.txt specification](https://llmstxt.org/) (see `llms-txt` skill for format).

## Documentation Philosophy

- Skills replace conventional `docs/` directories — per the [Agent Skills Specification](https://agentskills.io/specification)
- README.md = human-facing documentation
- [AGENTS.md](https://agents.md/) = AI-facing project context
- `skills/<name>/SKILL.md` = agent instructions
- `llms.txt` = LLM discovery ([spec](https://llmstxt.org/))
- **No separate docs folder**
