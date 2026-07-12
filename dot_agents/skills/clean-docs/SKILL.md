---
name: clean-docs
description: >
  Clean and modernize documentation in place. Enforce no em dashes, readable
  structure, proper Markdown formatting, accurate commands, current examples,
  resolved internal links, and user-focused guidance. Use when the user invokes
  /clean-docs, asks to clean docs, make docs up to date, improve README/AGENTS
  prose, remove AI-looking punctuation, or make docs easier for users to act on.
allowed-tools: Read, Grep, Glob, Bash(git *), Bash(rg *), Bash(fsrc *), Bash(agentspec *), Bash(jq *), Edit, Write
user-invocable: true
metadata:
  title: Clean Docs
  category: maintenance
  order: 21
---

# Clean Docs

Clean documentation so users can act on it quickly and agents can parse it reliably.

## When to Use

- The user invokes `/clean-docs`.
- The user asks to clean, polish, modernize, or tighten docs.
- The user asks for docs to be accurate, up to date, readable, or user-focused.
- The user asks to remove em dashes, AI-looking prose, stale examples, or formatting drift.
- The task touches README, AGENTS.md, llms.txt, docs/, skill files, or agent files.

## Default Workflow

1. **Inventory docs.** Find Markdown and text docs with `rg --files -g '*.md' -g '*.mdx' -g '*.txt'`.
2. **Run the hygiene gate.** Prefer the bundled checker:

   ```sh
   checker="${CLAUDE_SKILL_DIR:-$HOME/.agents/skills}/sync-docs/scripts/check-doc-hygiene.sh"
   "$checker" .
   ```

   In a chezmoi source tree before apply, use:

   ```sh
   dot_agents/skills/sync-docs/scripts/executable_check-doc-hygiene.sh .
   ```

3. **Verify claims before editing.** Check commands with `--help`, manifests, source files, tests, and existing configuration. Do not preserve claims that cannot be verified.
4. **Edit in place.** Improve structure, wording, examples, and links. Keep the existing document's purpose and do not invent unsupported features.
5. **Rerun the gate.** Fix failures until text hygiene, embedded examples, and agentspec validation pass.
6. **Report changes.** Summarize files changed, facts verified, and any items that still need a human decision.

## Cleanup Rules

| Rule | Standard |
| ---- | -------- |
| No em dashes | Do not use U+2014 anywhere in text, comments, help output, or docs. Use periods, colons, commas, or indexed bullets. |
| User-first | Lead with what the user can do, then prerequisites, then edge cases. |
| Accurate | Commands, paths, flags, and tool names must match current source or CLI help. |
| Focused | Remove filler, repeated setup prose, trailing summaries, and unsupported claims. |
| Scannable | Prefer short sections, tables for matrices, bullets for steps, and fenced code with language tags. |
| Actionable | Every major section should help users install, configure, run, verify, troubleshoot, or extend. |

## File-Specific Owners

Use these standards when the file type appears:

| Artifact | Standard |
| -------- | -------- |
| `README.md` | Read `write-readme` for structure, section order, quick start, examples, and Agent Skill placement. |
| `AGENTS.md` | Read `configure-ai` for agent instructions and the skills-vs-docs boundary. |
| `llms.txt` | Read `create-llms-txt` for LLM index structure. |
| `dot_agents/skills/*/SKILL.md` | Read `create-oss-skill` for frontmatter, trigger descriptions, and progressive disclosure. |
| Multi-file docs trees | Use `technical-documentation-architect` for information architecture decisions. |

## Editing Pattern

- **Before:** Long paragraphs, vague claims, stale commands, hidden prerequisites.
- **After:** Short purpose statement, exact command, expected result, next step.

Prefer this shape:

````markdown
## Task

One sentence stating when to use this task.

```sh
command --flag value
```

Expected result: what success looks like.
Troubleshooting: one or two common failures with fixes.
````

## Verification Checklist

- [ ] No em dash characters remain in tracked text files.
- [ ] Commands and flags match current CLI help or project manifests.
- [ ] Internal links point to existing files or anchors.
- [ ] Examples are runnable or clearly marked as illustrative.
- [ ] README and AGENTS.md agree on project purpose and key commands.
- [ ] Skill and agent files validate with `agentspec manage validate`.
- [ ] New or changed local skills are managed with `agentspec manage add "$(pwd)/dot_agents" --all-tools`.
- [ ] Local skill and agent hashes are accepted with `agentspec manage verify --accept --name <name>`.

## Gotchas

- Do not rewrite docs into marketing copy. Keep docs operational.
- Do not add placeholder links or sections.
- Do not use the checker as proof of accuracy by itself. It catches hygiene drift; factual claims still need source evidence.
- Do not edit deployed copies under `~/.agents/skills/` for chezmoi-managed skills. Edit `dot_agents/skills/` in the source tree.
