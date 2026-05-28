---
name: orchestrate-agents
description: >-
  Spawn and supervise a fleet of AI coding agents (claude, codex, copilot,
  gemini) across tmux windows and panes, then watch them and ping the user when
  one needs attention. Use when asked to run several agents in parallel,
  orchestrate or coordinate multiple agents, fan a task out across tools, set up
  a multi-session agent workflow, or "spawn a fleet". Uses agentspec to source
  prompts/personas and to read what each agent is actually doing.
allowed-tools: Bash
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
fleet=~/.agents/skills/orchestrate-agents/scripts/fleet.sh   # shared store; stable across tools
"$fleet" doctor          # confirm tmux + which agent CLIs + agentspec + notifier are present
```

If `doctor` shows a CLI missing, it just drops out of the preference order.

## Model

- **Fleet** = one tmux session. One per orchestration run.
- **Window** = a workstream group (per feature, per repo, per phase).
- **Pane** = one agent CLI. Reference agents by the **pane id** (`%7`) the helper
  returns, never by name (the user's shell hook may auto-rename windows; pane ids
  and `@fleet_*` tags are immune).

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

6. **Open the dashboard (optional):** `"$fleet" dashboard <fleet>` turns the control
   pane into a live, self-refreshing status table.

7. **Supervise** in a loop (below) until every agent reaches a terminal state.

8. **Wrap up.** Summarize each agent's outcome, citing transcripts (step on
   "understand what's running"). Tear down with `"$fleet" kill <fleet>` only after
   the user has what they need, or leave it attached for them to inspect.

## Supervision loop

Poll, classify, act. Roughly every 20 to 45 seconds:

```bash
"$fleet" list <fleet>    # TSV: window  name  tool  STATE  pane
```

For each agent's `STATE`:

- **running** Leave it. Do not interrupt.
- **needs-permission** The agent is blocked on an approval prompt. **Ping the user**
  and wait for their decision. Do not auto-approve. When told, relay the answer:
  `"$fleet" send <pane> "1"` (or whatever the prompt expects, see the matrix).
- **error** Capture context (`"$fleet" capture <pane>`), **ping the user** with a
  one-line diagnosis, and propose a fix. Do not blindly retry auth or rate-limit
  errors.
- **idle** Unchanged past the idle threshold. Could be done or stuck. Read the
  transcript (below) to tell which. If done, note the result; if stuck, **ping**.

Tune idle sensitivity with `FLEET_IDLE_SECS` (default 30).

## Alerting (all four channels)

`"$fleet" ping <fleet> "<message>" [pane]` fires every channel at once:

1. **In-chat:** the helper prints `PING[...]` to stderr. **You must also surface a
   clear, specific line to the user in this conversation** (the helper cannot write
   to chat itself). This is the channel that always matters.
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
