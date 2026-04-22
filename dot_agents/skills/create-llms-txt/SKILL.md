---
name: create-llms-txt
description: >
  Generate a spec-compliant llms.txt file for any project by analyzing its
  codebase, docs, and public URLs. Use when creating an llms.txt, making a
  project LLM-discoverable, or when the user mentions "llms.txt" in the
  context of generating or scaffolding one.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write, Agent, WebFetch
metadata:
  title: Create llms.txt
  category: ai
  order: 1
---

# Create llms.txt

Generate a high-quality, spec-compliant `llms.txt` that gives LLMs maximum understanding of a project with minimum tokens.

## Spec (llmstxt.org)

The file uses markdown with this exact section order:

1. **H1** (required) project name
2. **Blockquote** (optional) one-paragraph summary with key context
3. **Prose** (optional) additional detail, any markdown except headings
4. **H2 sections** (optional) lists of `[name](url): description` links
5. **`## Optional`** (special) links that can be skipped for shorter context

No other heading levels allowed. Every list entry must be a markdown hyperlink. Descriptions after `:` are optional.

```markdown
# Project Name

> One-paragraph summary covering what it is, who it's for, and key capabilities.

## Docs

- [README](url): Installation, usage, examples
- [API Reference](url): Endpoint documentation

## Optional

- [CONTRIBUTING](url): How to contribute
```

## Procedure

### 1. Discover project identity

Read these files (skip missing ones):
- **`README.md`** name, summary, features
- **`AGENTS.md`** architecture, key directories
- **`package.json` / `Cargo.toml` / `pyproject.toml` / `go.mod`** name, description, repo URL
- **`CHANGELOG.md`** exists? link it
- **`CONTRIBUTING.md`** exists? link in Optional
- **`LICENSE`** exists? link in Optional

Determine the **repo base URL** from git remote or manifest. All links must be absolute URLs pointing to the main branch (e.g. `https://github.com/{owner}/{repo}/blob/main/{path}`).

### 2. Identify key files

Scan for files that help an LLM understand the project:

- Entry points (`main.go`, `src/lib.rs`, `src/index.ts`, `app.py`, etc.)
- Public API surface (exported modules, route definitions, CLI entry)
- Config files that define behavior (`Justfile`, `Makefile`, `docker-compose.yml`, `pyproject.toml`)
- Schema definitions (OpenAPI, GraphQL, DB migrations)
- Skills (`skills/*/SKILL.md`)

Limit to 6-10 key files. Prefer files that explain *what the project does* over internal implementation.

### 3. Write the blockquote

One paragraph, 2-3 sentences max. Cover:
- What the project is
- Who it's for / what problem it solves
- Key differentiating capabilities

Do NOT pad with generic filler. Every word should help an LLM decide whether this project is relevant to a query.

### 4. Organize sections

Use these H2 sections (omit empty ones):

| Section | Contents |
|---------|----------|
| `## Docs` | README, AGENTS.md, API docs, guides |
| `## API / Key Files` | Entry points, public API, config, schemas |
| `## Skills` | Agent skills if `skills/` directory exists |
| `## Optional` | CONTRIBUTING, LICENSE, changelog, secondary docs |

### 5. Write link descriptions

Each `: description` should be 3-10 words explaining what the LLM will find there. Skip the description only if the link name is already self-explanatory.

Bad: `- [README](url): The README file`
Good: `- [README](url): Installation, usage, and examples`

### 6. Validate

Before writing the file, check:
- [ ] H1 is the first line, matches project name
- [ ] Blockquote is present and concise
- [ ] All URLs are absolute and resolve to real files
- [ ] Sections appear in order: Docs, API/Key Files, domain sections, Optional last
- [ ] No H3+ headings used (spec only allows H1 and H2)
- [ ] `## Optional` is last if present
- [ ] Total file is under 50 lines (aim for density)
- [ ] No duplicate links across sections
- [ ] Every list item has a markdown hyperlink

## Gotchas

- **No relative links.** LLMs fetch `llms.txt` from a URL. Relative paths break. Always use absolute URLs.
- **Don't link directories.** Link to the actual markdown/source file, not a directory path. `skills/configure-ai/SKILL.md` not `skills/configure-ai/`.
- **The `## Optional` heading is semantic.** It tells LLMs they can drop these links when context is tight. Put truly skippable content there; not your API docs.
- **Don't duplicate the README.** The blockquote is a *summary for LLMs*, not a copy of your README's first paragraph. Write it fresh with an LLM audience in mind.
- **Keep it short.** An llms.txt that's 200 lines defeats the purpose. Aim for 20-50 lines. If you need more, your project needs better docs, not a longer index.
- **Repo URL detection**: check `git remote get-url origin` and normalize to HTTPS. Strip `.git` suffix. Use `blob/main/` for file links.
