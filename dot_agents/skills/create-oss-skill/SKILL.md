---
name: create-oss-skill
description: >
  Create well-formed Agent Skills following the agentskills.io specification.
  Scaffold directories, write SKILL.md files, bundle scripts, and structure
  instructions for progressive disclosure. Use when creating a new skill,
  reviewing skill structure, optimizing a skill description, or setting up
  evals for skill quality.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
metadata:
  title: Create OSS Skill
  category: ai
  order: 2
---

# Create OSS Skill

Create Agent Skills that comply with the [agentskills.io spec](https://agentskills.io/specification) and follow authoring best practices.

## Directory Structure

```
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: documentation
├── assets/           # Optional: templates, resources
└── evals/            # Optional: eval test cases
    ├── evals.json
    └── files/
```

Place skills in `skills/<skill-name>/SKILL.md` (project-level) or `~/.agents/skills/<skill-name>/SKILL.md` (user-level cross-client).

## Frontmatter

| Field | Required | Constraints |
|-------|----------|-------------|
| `name` | Yes | 1-64 chars. Lowercase `a-z`, numbers, hyphens. No leading/trailing/consecutive hyphens. **Must match parent directory name.** |
| `description` | Yes | 1-1024 chars. What it does **and when to use it**. Include trigger keywords. |
| `license` | No | License name or reference to bundled file. |
| `compatibility` | No | 1-500 chars. Environment requirements. Only if needed. |
| `allowed-tools` | No | Space-delimited pre-approved tools. |
| `metadata` | No | Arbitrary key-value map. |

Quote YAML values containing colons: `description: "Use when: the user asks"`.

## Writing Effective Descriptions

The description carries the entire burden of triggering; agents see only `name` + `description` at startup (~50-100 tokens) and decide whether to activate from this alone.

**Principles:**
- **Imperative phrasing**: "Use this skill when..." not "This skill does..."
- **Focus on user intent**: Describe what the user is trying to achieve, not internal mechanics
- **Be pushy**: Explicitly list contexts, including cases where the user doesn't name the domain directly
- **Include keywords**: Specific terms agents will match against

Good:
```yaml
description: >
  Analyze CSV and tabular data files. Compute summary statistics,
  add derived columns, generate charts, and clean messy data. Use this
  skill when the user has a CSV, TSV, or Excel file and wants to
  explore, transform, or visualize the data, even if they don't
  explicitly mention "CSV" or "analysis."
```

Bad: `description: Helps with PDFs.`

To test and optimize descriptions systematically, see [references/optimizing-descriptions.md](references/optimizing-descriptions.md).

## Writing Effective Instructions

### Start from Real Expertise

Don't rely solely on LLM general knowledge. Ground skills in:
- **Hands-on tasks**: Complete a real task with an agent, note corrections and context you provided, extract the reusable pattern
- **Project artifacts**: Internal docs, runbooks, API specs, code review comments, incident reports, version control history

### Spend Context Wisely

The SKILL.md body competes for attention with everything else in the context window.

- **Add what the agent lacks, omit what it knows.** Don't explain what a PDF is. Do specify which library to use and why.
- **Aim for moderate detail.** Concise stepwise guidance with a working example outperforms exhaustive documentation.
- **Design coherent units.** Too narrow = multiple skills load for one task. Too broad = triggers on wrong tasks.

### Calibrate Control

- **Give freedom** when multiple approaches are valid (explain *why* so the agent adapts)
- **Be prescriptive** when operations are fragile or a specific sequence must be followed
- **Provide defaults, not menus**: Pick one tool/approach, mention alternatives briefly

### Patterns for Instructions

**Gotchas sections** highest-value content. Concrete corrections to mistakes the agent will make:
```markdown
## Gotchas
- The `users` table uses soft deletes. Include `WHERE deleted_at IS NULL`.
- User ID is `user_id` in DB, `uid` in auth, `accountId` in billing.
```

**Output templates** more reliable than prose descriptions:
```markdown
## Report structure
Use this template:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

**Checklists** for multi-step workflows with dependencies:
```markdown
## Workflow
- [ ] Step 1: Analyze (run `scripts/analyze.py`)
- [ ] Step 2: Validate (run `scripts/validate.py`)
- [ ] Step 3: Execute (run `scripts/execute.py`)
```

**Validation loops** instruct the agent to verify its own work:
```markdown
1. Make edits
2. Run `python scripts/validate.py output/`
3. If fails: fix issues, re-validate
4. Only proceed when validation passes
```

**Plan-validate-execute** for batch/destructive operations:
```markdown
1. Generate plan → `plan.json`
2. Validate plan against source of truth
3. Only execute after validation passes
```

### Favor Procedures over Declarations

Teach *how to approach* a class of problems, not *what to produce* for a specific instance. The approach should generalize even when individual details are specific.

## Progressive Disclosure Budget

| Tier | Content | Budget |
|------|---------|--------|
| 1. Catalog | `name` + `description` | ~50-100 tokens |
| 2. Instructions | SKILL.md body | <5000 tokens / <500 lines |
| 3. Resources | scripts/, references/, assets/ | On demand |

**Keep SKILL.md under 500 lines.** Move detailed reference material to separate files. Tell the agent *when* to load each file: "Read `references/api-errors.md` if the API returns a non-200 status" is better than "see references/ for details."

## Bundled Scripts

### One-off Commands

Reference existing packages directly; no `scripts/` needed:
- `uvx ruff@0.8.0 check .` (Python)
- `npx eslint@9 --fix .` (Node)
- `go run golang.org/x/tools/cmd/goimports@v0.28.0 .` (Go)

Pin versions for reproducibility. State prerequisites in `compatibility`.

### Self-contained Scripts

Bundle in `scripts/` with inline dependency declarations:

```python
# /// script
# dependencies = ["beautifulsoup4"]
# ///
from bs4 import BeautifulSoup
# ... run with: uv run scripts/extract.py
```

### Designing Scripts for Agents

- **No interactive prompts** agents can't respond to TTY input. Use flags/env vars/stdin.
- **`--help` output** primary way agents learn the interface. Include description, flags, examples.
- **Helpful error messages** say what went wrong, what was expected, what to try.
- **Structured output** JSON/CSV over free-form text. Data to stdout, diagnostics to stderr.
- **Idempotent** "create if not exists" over "create and fail on duplicate."
- **Dry-run support** `--dry-run` for destructive operations.
- **Predictable output size** default to summary/limit, support `--offset` for pagination.

### When to Bundle

Compare agent execution traces across test cases. If the agent independently reinvents the same logic each run (chart building, format parsing, output validation), write a tested script once and bundle it.

## Evaluating Skills

Test whether a skill produces good outputs using structured evals. See [references/evaluating-skills.md](references/evaluating-skills.md) for the full eval workflow.

Core loop:
1. Write test cases in `evals/evals.json` (prompt + expected output + optional files)
2. Run each test **with** and **without** the skill
3. Add assertions after seeing first outputs
4. Grade assertions (PASS/FAIL with evidence)
5. Aggregate into `benchmark.json` (pass rate, tokens, time deltas)
6. Human review for qualities assertions can't capture
7. Iterate: feed failures + feedback + transcripts into skill improvements

## Checklist

Before publishing:

1. `name` matches parent directory exactly
2. `name` is lowercase alphanumeric + hyphens, 1-64 chars
3. `description` is non-empty, describes what AND when, under 1024 chars
4. `description` uses imperative phrasing with trigger keywords
5. YAML frontmatter is valid (colons quoted)
6. Body is under 500 lines / ~5000 tokens
7. Reference material split into separate files with conditional load instructions
8. Scripts are self-contained, non-interactive, with `--help` and structured output
9. `compatibility` included only if environment-specific requirements exist
10. Validate with `skills-ref validate ./my-skill` if available

## Template

```markdown
---
name: <skill-name>
description: >
  <What it does. Capabilities>. Use when <trigger conditions>,
  even if the user doesn't explicitly mention <domain keywords>.
license: Apache-2.0
---

# <Skill Title>

## When to Use

<Clear trigger conditions.>

## Instructions

<Step-by-step guidance. Explain *why* for non-obvious steps.>

## Gotchas

<Concrete corrections to mistakes the agent will make without being told.>

## Examples

<Input/output examples demonstrating expected behavior.>
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Vague description | Add trigger keywords, capability list, imperative phrasing |
| Description says "This skill does..." | Use "Use this skill when..." |
| Name doesn't match directory | Rename directory or `name` field to match |
| Uppercase/underscores in name | Lowercase + hyphens only |
| Unquoted YAML colons | Quote: `description: "Use when: the user asks"` |
| Everything in one file | Split into references/, scripts/, assets/ |
| Missing "when to use" | Always include trigger conditions in description |
| Body too long | Target <500 lines, offload detail to reference files |
| Generic LLM-generated content | Ground in real expertise, project artifacts, hands-on tasks |
| Exhaustive rules over examples | Concise steps + working example outperform rule lists |
| Menus of equal options | Pick a default, mention alternatives briefly |
| Scripts with interactive prompts | Use flags/env vars/stdin, never TTY prompts |
| No validation step | Add validation loops or plan-validate-execute patterns |
