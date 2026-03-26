---
name: extend-oss-skills-to-claude
description: >
  Extend standard agentskills.io skills with Claude Code-specific features —
  invocation control, subagent execution, dynamic context injection, string
  substitutions, model/effort overrides, and deployment scoping. Use when
  adapting a portable skill for Claude Code, adding Claude-specific frontmatter,
  setting up subagent delegation, or configuring skill permissions.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
metadata:
  title: Extend OSS Skills to Claude
  category: ai
  order: 3
---

# Extend OSS Skills to Claude Code

Take a standard [agentskills.io](https://agentskills.io/specification) skill and layer on Claude Code execution features. The base spec defines a portable file format; Claude Code turns it into an execution framework.

## What the Standard Covers

The open standard defines: `name` (required), `description` (required), `license`, `compatibility`, `metadata`, `allowed-tools` (space-delimited). These fields work across all compatible agents (Cursor, Gemini CLI, OpenCode, Goose, etc.). Start with `create-oss-skill` for the base format.

## Claude Code Extended Frontmatter

These fields are Claude Code-specific. Other agents ignore them.

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `argument-hint` | string | — | Autocomplete hint: `[issue-number]`, `[filename] [format]` |
| `disable-model-invocation` | bool | `false` | `true` = only the user can trigger via `/name`. Removes from agent context entirely. |
| `user-invocable` | bool | `true` | `false` = hidden from `/` menu. Agent-only background knowledge. |
| `model` | string | session | Override model when skill is active. |
| `effort` | string | session | Override reasoning effort: `low`, `medium`, `high`, `max`. |
| `context` | string | — | `fork` = run in isolated subagent context. |
| `agent` | string | `general-purpose` | Subagent type when `context: fork`. Built-in: `Explore`, `Plan`, `general-purpose`. Custom: any `.claude/agents/` definition. |
| `hooks` | object | — | Lifecycle hooks scoped to this skill. See [hooks docs](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents). |

### Differences from Standard

| Aspect | Standard | Claude Code |
|--------|----------|-------------|
| `name` | Required | Optional (falls back to directory name) |
| `description` | Required | Recommended (falls back to first paragraph) |
| `allowed-tools` | Space-delimited | Comma-delimited |
| Extra fields | Ignored | Execution control, subagent delegation |

Keep `name` and `description` required in practice — portability matters.

## Invocation Control

Two fields control who can trigger a skill:

```yaml
# User-only: deploy, commit, send-message — side effects you control
disable-model-invocation: true

# Agent-only: background context the user shouldn't invoke directly
user-invocable: false
```

| Config | User triggers | Agent triggers | In agent context |
|--------|--------------|----------------|------------------|
| defaults | Yes | Yes | Description only |
| `disable-model-invocation: true` | Yes | No | Not loaded |
| `user-invocable: false` | No | Yes | Description only |

Use `disable-model-invocation: true` for anything with side effects. Use `user-invocable: false` for domain knowledge the agent should know but isn't an action.

## String Substitutions

Available in skill body content:

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed after `/skill-name` |
| `$ARGUMENTS[N]` or `$N` | Positional argument (0-based) |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Directory containing this SKILL.md |

If `$ARGUMENTS` is absent from content, arguments are appended as `ARGUMENTS: <value>`.

```yaml
---
name: fix-issue
disable-model-invocation: true
argument-hint: "[issue-number]"
---
Fix GitHub issue $ARGUMENTS following our coding standards.
```

Multi-argument example:

```yaml
---
name: migrate-component
argument-hint: "[component] [from] [to]"
---
Migrate the $0 component from $1 to $2.
```

## Dynamic Context Injection

The `` !`command` `` syntax runs shell commands **before** the skill content reaches the agent. Output replaces the placeholder inline.

```yaml
---
name: pr-summary
context: fork
agent: Explore
---
## Context
- PR diff: !`gh pr diff`
- Changed files: !`gh pr diff --name-only`
- PR comments: !`gh pr view --comments`

Summarize this pull request.
```

This is preprocessing — the agent sees rendered output, not the commands. Use for fetching live data (git state, API responses, environment info).

## Subagent Execution

`context: fork` runs the skill in an isolated context without conversation history. The skill body becomes the subagent's task prompt.

```yaml
---
name: deep-research
description: Research a topic thoroughly across the codebase
context: fork
agent: Explore
---
Research $ARGUMENTS thoroughly:
1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings with specific file references
```

**When to fork:**
- Task is self-contained and doesn't need conversation history
- You want isolation (read-only exploration, parallel research)
- The skill has explicit step-by-step instructions (not just guidelines)

**When NOT to fork:**
- Skill is reference content (conventions, patterns, style guides)
- Skill needs to interact with the user's ongoing conversation
- Instructions are guidelines without a concrete task

### Agent Types

| Agent | Use case |
|-------|----------|
| `Explore` | Read-only codebase exploration, research |
| `Plan` | Planning and analysis without modifications |
| `general-purpose` | Full tool access (default) |
| Custom (`.claude/agents/`) | Specialized agents with preloaded skills |

## Deployment Scoping

Claude Code adds a hierarchy the standard doesn't define:

| Scope | Path | Applies to |
|-------|------|------------|
| Enterprise | Managed settings | All org users |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin enabled |

Priority: enterprise > personal > project. Plugin skills use `plugin-name:skill-name` namespace (no conflicts).

Monorepo support: skills in nested `.claude/skills/` directories auto-discovered when working in subdirectories.

## Tool Restrictions and Permissions

Claude Code extends `allowed-tools` beyond the standard:

```yaml
# Standard (space-delimited, informational)
allowed-tools: Read Grep Glob

# Claude Code (comma-delimited, enforced as permission grants)
allowed-tools: Read, Grep, Glob, Bash(git *)
```

Claude Code also supports pattern-based tool permissions:
- `Bash(git *)` — allow git commands
- `Bash(npm test)` — allow specific command
- `Read, Grep, Glob` — read-only mode

Users can restrict skill access via permission rules:
```
Skill(deploy *)    # deny deploy skill
Skill(commit)      # allow commit skill
```

## Model and Effort Overrides

Override per-skill when the default isn't appropriate:

```yaml
---
name: complex-analysis
model: claude-opus-4-6
effort: max
context: fork
---
```

Use sparingly. Most skills work fine with session defaults.

## Lifecycle Hooks

Scope hooks to skill execution for pre/post processing:

```yaml
---
name: deploy
hooks:
  pre: scripts/pre-deploy-check.sh
  post: scripts/notify-slack.sh
---
```

See [hooks documentation](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents) for full configuration.

## Extended Thinking

Include the word "ultrathink" in skill content to enable extended thinking mode for the skill's execution.

## Portability Checklist

When extending a standard skill for Claude Code:

1. Keep standard fields (`name`, `description`, `license`, `compatibility`) intact and valid
2. Add Claude Code fields alongside — other agents ignore unknown frontmatter
3. Switch `allowed-tools` delimiter from spaces to commas
4. Test the skill still works as plain markdown instructions (graceful degradation)
5. Document Claude-specific features in a comment or separate section so contributors understand
6. Use `${CLAUDE_SKILL_DIR}` instead of hardcoded paths for script references

## Template

```yaml
---
name: <skill-name>
description: >
  <What it does>. Use when <trigger conditions>.
# --- Standard fields above, Claude Code extensions below ---
argument-hint: "[arg1] [arg2]"
disable-model-invocation: true
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob
effort: high
metadata:
  author: <org>
  version: "1.0"
---

# <Skill Title>

## Context
- Current branch: !`git branch --show-current`
- Recent changes: !`git log --oneline -5`

## Instructions

<Step-by-step guidance using $ARGUMENTS.>

## Gotchas

<Claude Code-specific pitfalls.>
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `context: fork` for reference/guideline content | Fork needs a concrete task — use inline for guidelines |
| Forgetting `disable-model-invocation` on side-effect skills | Always set for deploy, commit, send, publish |
| Hardcoding script paths | Use `${CLAUDE_SKILL_DIR}/scripts/` |
| Space-delimited `allowed-tools` | Claude Code uses commas |
| Setting `user-invocable: false` expecting it blocks Skill tool | Use `disable-model-invocation: true` to block programmatic invocation |
| Forking without explicit instructions | Subagent gets guidelines but no task — returns nothing useful |
| Overusing model/effort overrides | Session defaults work for most skills |
