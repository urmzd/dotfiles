---
name: orchestrate-agents
description: >-
  Orchestrate multiple agent CLIs (Claude, Codex, Gemini) via tmux with a shared
  fleet store, dispatching one guardian subagent per pane. Use when running a
  multi-agent session, dispatching parallel work, or coordinating subagents
  across panes.
allowed-tools: Bash, Task
user-invocable: true
---

# Orchestrate Agents

Run several interactive agent CLIs at once inside one tmux session, supervise
them, and alert the user the moment one is blocked, errored, idle, or done. You
are the orchestrator: careful, never silently let an agent stall.

`scripts/fleet.sh` owns the fragile tmux plumbing (spawn, send, capture, idle
detection, alerting). You decide what to spawn and when to ping.

Set the helper path once, then drive it:

```bash
fleet="${CLAUDE_SKILL_DIR:-$HOME/.agents/skills}/orchestrate-agents/scripts/fleet.sh"   # shared store; stable across tools
"$fleet" doctor          # confirm tmux + which agent CLIs + agentspec + notifier are present
```

If `doctor` shows a CLI missing, it just drops out of the preference order.

## Model

- **Fleet** = one tmux session. One per orchestration run.
- **Window** = a workstream group (per feature, per repo, per phase).
- **Pane** = one agent CLI. Reference agents by the **pane id** (`%7`) the helper
  returns, never by name (the user's shell hook may auto-rename windows; pane ids
  and `@fleet_*` tags are immune).
- **Guardian** = a `guardian` subagent dedicated to one pane. Spawned at the same
  moment as the pane. The orchestrator never reads `capture` directly during the
  supervision loop; it reads the guardian's contract lines instead.

Tool preference when a workstream does not pin one: **claude, codex** first, then
**copilot**, then **gemini**. See [references/agent-clis.md](references/agent-clis.md)
for each CLI's launch, headless, auto-approve, and resume flags.

## Workflow

1. **Plan.** Turn the request into workstreams (windows) and agents (panes). State
   the plan to the user before spawning: which tools, how many, what each does.

2. **Source prompts (optional).** To assign a persona or skill as an agent's brief,
   list what is available with `agentspec manage list` (add `--format json` to
   parse). Feed the chosen prompt to the agent in step 5.

3. **Start the fleet:** `"$fleet" start <fleet-name>`. Print the `ATTACH=` line so
   the user can `tmux attach` and watch.

4. **Create groups and spawn agents:**
   ```bash
   win=$("$fleet" group <fleet> backend | awk -F= '/WINDOW/{print $2}')
   pane=$("$fleet" spawn <fleet> "$win" claude --name api --dir ~/repo | awk -F= '/PANE/{print $2}')
   ```
   `spawn <fleet> <window> <tool>` where tool is `auto|claude|codex|copilot|gemini`.
   It reuses the window's first pane for the first agent, splits for the rest.

5. **Brief each agent.** Wait until the pane shows a ready input box
   (`"$fleet" capture <pane>` until the CLI has booted), then send the task:
   ```bash
   "$fleet" send <pane> "Refactor the auth module. Run tests when done."
   ```
   `send` pastes multi-line text safely and submits.

   5b. **Dispatch a guardian for this pane.** Immediately after the first
   successful send, dispatch a `guardian` subagent for this pane (Claude Code:
   `Task` tool with `subagent_type=guardian`; Codex: `/agent guardian` inside the
   orchestrator session, or `codex --profile guardian` in a sidecar pane). Pass
   `<fleet>`, `<pane>`, the agent name, and the `fleet.sh` path as the brief.
   The guardian owns this pane until terminal state. See **Agent invocations**
   below for the exact calls.

6. **Open the dashboard (optional):** `"$fleet" dashboard <fleet>` turns the control
   pane into a live, self-refreshing status table.

7. **Supervise.** The orchestrator no longer polls `list`/`capture` for liveness.
   It consumes guardian contract lines (see **Integration contract with guardian**
   below) as events. The orchestrator's only loop responsibility is: receive
   contract line, decide if user input is needed, surface the line to chat,
   collect the user's reply, instruct the originating guardian to relay it via
   `fleet.sh send`.

8. **Wrap up.** Summarize each agent's outcome, citing transcripts (step on
   "understand what's running"). Tear down with `"$fleet" kill <fleet>` only after
   the user has what they need, or leave it attached for them to inspect.

## Supervision loop (delegated to guardians)

Each guardian runs its own poll/classify cycle (see the guardian persona). The
orchestrator treats each contract line as an event:

- **needs-permission** surface to chat, await user, relay decision through the
  originating guardian.
- **error** surface to chat with the guardian's quoted error line, await user
  instruction. Do not blindly retry auth or rate-limit errors.
- **done** mark the pane complete in the orchestrator's tally.
- **stuck** surface to chat and let the user choose between kill, send a nudge,
  or wait.
- **relayed** confirmation only; advance to the next event.

`fleet.sh list <fleet>` and `fleet.sh capture <pane>` remain available, but the
guardian is their primary consumer. The orchestrator only reads them directly
when a guardian is unreachable or the user explicitly overrides.

Tune idle sensitivity with `FLEET_IDLE_SECS` (default 30); the knob is read by
each guardian, not the orchestrator.

## Agent invocations

Spawn exactly one guardian per pane, immediately after step 5's first `send`.

**Claude Code (orchestrator inside Claude):** use the `Task` tool.

```text
Task({
  subagent_type: "guardian",
  description: "Guard pane %7 in fleet refactor-auth",
  prompt: "You are guarding pane %7 (agent: api, tool: claude) in fleet \
refactor-auth. fleet.sh is at ~/.agents/skills/orchestrate-agents/scripts/fleet.sh. \
Follow the guardian persona: poll list, capture on transition, emit one contract \
line per state change in the format GUARDIAN[%7]: <state> - <summary> - <action>. \
Never call send/spawn/kill/group on your own initiative."
})
```

**Codex (orchestrator inside Codex):** run inside the orchestrator session:

```bash
/agent guardian fleet=refactor-auth pane=%7 name=api tool=claude \
  fleet_sh=~/.agents/skills/orchestrate-agents/scripts/fleet.sh
```

or in a sidecar pane:

```bash
codex --profile guardian -- \
  "Guard pane %7 in fleet refactor-auth. fleet.sh=~/.agents/skills/orchestrate-agents/scripts/fleet.sh"
```

Both invocations brief the guardian with the four facts it needs: fleet name,
pane id, agent display name, and the `fleet.sh` path.

## Alerting (all four channels)

Guardians produce the alerts; the orchestrator is the megaphone. The in-chat
channel is fed by the orchestrator forwarding the guardian's contract line
verbatim, and the orchestrator must NOT paraphrase guardian output before
showing it to the user.

`"$fleet" ping <fleet> "<message>" [pane]` fires every channel at once:

1. **In-chat:** the helper prints `PING[...]` to stderr. **You must also surface
   the guardian's contract line, unmodified, to the user in this conversation**
   (the helper cannot write to chat itself). This is the channel that always
   matters.
2. **macOS notification** via `osascript` (Notification Center, with sound).
3. **Terminal bell + status line** on the pane that needs attention.
4. **Status dashboard pane** (when opened in step 6) reflects the new state.

Ping when, and only when: an agent needs permission, errored, finished a
workstream, or is stuck. Do not ping for normal progress.

## Understand what is running

Liveness comes from tmux (`list`, `capture`). Substance comes from agentspec,
which reads each tool's own session store:

```bash
agentspec session list <claude|codex|copilot|gemini>     # id | time | first prompt
agentspec session export <tool> --last                   # full transcript as markdown
```

Use the transcript to disambiguate an `idle` agent (done vs stuck), to summarize
what each agent accomplished, and to brief a follow-up agent with prior context.

## Safety (default: prompt on, ping to approve)

- Spawn agents **bare** so their normal permission prompts stay on. The orchestrator
  detects a blocked agent and pings the user; the user decides.
- Do **not** pass `--dangerously-skip-permissions`, `--yolo`, `--allow-all`, or
  `codex --dangerously-bypass-...` unless the user explicitly asks for an unattended
  / full-auto run for this fleet. Auto-approve flags per tool are in the matrix.
- Never approve a destructive or outward-facing action on an agent's behalf. Surface
  it and wait.
- One fleet per run; name it after the task. Tear down with `kill` when finished.
- **Each pane has exactly one guardian.** The orchestrator must not approve, kill,
  or send to a pane without going through (or explicitly overriding with the
  user's consent) that pane's guardian. If a guardian crashes or its thread ends,
  treat the pane as unsupervised and ping the user before any further action on it.

## Integration contract with guardian

Guardian-to-orchestrator messages are single lines, one per state transition,
written to stdout:

    GUARDIAN[<pane>]: <state> - <one-line summary> - <action>

- `<pane>` is the tmux pane id (e.g. `%7`), never the agent's display name.
- `<state>` is exactly one of: `running` (only on first attach),
  `needs-permission`, `error`, `idle`, `stuck`, `done`, `relayed`.
- `<one-line summary>` is a literal quote from `fleet.sh capture` when
  applicable, trimmed to fit one line; no paraphrase.
- `<action>` is one of: `awaiting user decision`,
  `awaiting orchestrator instruction`, `no action`,
  `relayed: "<verbatim string sent>"`.

**Orchestrator obligations:**

- Surface every non-`running` line to chat verbatim.
- For `needs-permission` and `stuck`, block on user input before instructing
  the guardian.
- Relay user decisions by telling the originating guardian to
  `fleet.sh send <pane> "<verbatim>"` (guardian then emits a `relayed` line).
- Guardians never call `send`, `spawn`, `kill`, or `group` on their own
  initiative; if a relay is needed, the orchestrator must instruct it.
