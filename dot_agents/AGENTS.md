[agents-home] Agent & Skill Registry

## Overview

`~/.agents/` is the user-level resource registry managed by [agentspec](https://github.com/anthropics/agentspec). It separates **agents** (personas/subagents that define thinking style) from **skills** (capabilities that define what to do).

## Structure

```
~/.agents/
├── AGENTS.md            # This file
├── agents/              # Persona and subagent definitions (AGENT.md format)
│   ├── architect.md     # Interface-first systems design
│   ├── curator.md       # Consistency and polish
│   ├── debugger.md      # Root-cause analysis
│   ├── ideator.md       # Creative exploration
│   ├── strategist.md    # Multi-system orchestration
│   ├── writer.md        # Technical documentation
│   └── technical-documentation-architect.md
└── skills/              # Chezmoi-managed; agentspec links to tools
```

## Agents vs Skills

| Aspect | Agents (`agents/`) | Skills (`skills/`) |
|--------|-------------------|-------------------|
| Format | `<name>.md` with agent frontmatter | `<name>/SKILL.md` with skill frontmatter |
| Purpose | Define HOW to think and communicate | Define WHAT to do and WHEN |
| Usage | Subagent types, persona activation | Tool invocation, domain knowledge |
| Managed by | chezmoi (source of truth in dotfiles) | chezmoi (source of truth); agentspec links to tools |

## Commands

```bash
agentspec manage list              # List all managed resources
agentspec manage add <source>      # Add a skill or agent
agentspec manage link <name> <tool> # Link resource to a tool (claude-code, codex, etc.)
agentspec sync --fast              # Sync and discover resources
agentspec status                   # Show managed vs unmanaged inventory
```

## Adding Agents and Skills

Both agents and skills are managed in the chezmoi dotfiles repo at `dot_agents/`. After editing:

```bash
chezmoi apply    # Deploy to ~/.agents/
agentspec sync   # Re-discover, adopt, and link
```

## Linking to Tools

After agents are deployed, link them to specific AI tools:

```bash
agentspec manage link architect claude-code
agentspec manage link debugger claude-code
```

This creates the appropriate symlinks (e.g., `~/.claude/agents/architect.md`).
