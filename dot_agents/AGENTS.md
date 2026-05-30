[agents-home] Agent & Skill Registry

## Overview

`~/.agents/` is the user-level resource registry managed by [agentspec](https://github.com/urmzd/agentspec). It separates **agents** (personas/subagents that define thinking style) from **skills** (capabilities that define what to do).

The registry is **cross-project**. Once deployed, agents and skills are usable from any project, by any tool (claude-code, codex, gemini, copilot), via `agentspec manage link <name> <tool>`. They are not specific to the dotfiles repo.

## Structure

```
~/.agents/
├── AGENTS.md            # This file
├── agents/              # Persona and subagent definitions (AGENT.md format)
│   ├── architect.md     # Interface-first systems design
│   ├── curator.md       # Consistency and polish
│   ├── debugger.md      # Root-cause analysis
│   ├── guardian.md      # Supervises orchestrated agent fleets (pairs with orchestrate-agents)
│   ├── ideator.md       # Creative exploration
│   ├── strategist.md    # Multi-system orchestration
│   ├── technical-documentation-architect.md  # Structured docs & architecture
│   └── writer.md        # Technical documentation
└── skills/              # Capabilities; agentspec links to tools
```

## Agents vs Skills

| Aspect | Agents (`agents/`) | Skills (`skills/`) |
|--------|-------------------|-------------------|
| Format | `<name>.md` with agent frontmatter | `<name>/SKILL.md` with skill frontmatter |
| Purpose | Define HOW to think and communicate | Define WHAT to do and WHEN |
| Usage | Subagent types, persona activation | Tool invocation, domain knowledge |
| Managed by | agentspec (source typically tracked in a dotfile manager) | agentspec |

## Commands

```bash
agentspec manage list              # List all managed resources
agentspec manage add <source>      # Add a skill or agent
agentspec manage link <name> <tool> # Link resource to a tool (claude-code, codex, etc.)
agentspec sync --fast              # Sync and discover resources
agentspec status                   # Show managed vs unmanaged inventory
```

## Editing Agents and Skills

For users of this repo, the **source** for agents and skills lives in chezmoi at `~/.local/share/chezmoi/dot_agents/`. Edit there, then:

```bash
chezmoi apply    # Deploy to ~/.agents/
agentspec sync   # Re-discover, adopt, and link
```

If you maintain agents/skills outside chezmoi (different dotfile manager, no manager at all, or another git repo), `~/.agents/` is still the canonical deployed location. Point your own sync mechanism at it, then run `agentspec sync`.

## Using Agents in Other Projects

After `chezmoi apply` (or however you populate `~/.agents/`), the agents and skills are available globally. From inside any other project:

```bash
# Inside ~/work/some-other-project
agentspec manage link architect claude-code
agentspec manage link guardian codex
agentspec manage link orchestrate-agents claude-code
agentspec sync --fast
```

This creates the tool-specific symlinks (e.g., `~/.claude/agents/architect.md`, `~/.codex/agents/guardian.md`) so the tool sees the resource. Nothing about this is dotfiles-repo-specific.

## Linking to Tools

After agents are deployed, link them to specific AI tools:

```bash
agentspec manage link architect claude-code
agentspec manage link debugger claude-code
agentspec manage link guardian codex      # guardian also ships as a Codex profile
```

This creates the appropriate symlinks (e.g., `~/.claude/agents/architect.md`).
