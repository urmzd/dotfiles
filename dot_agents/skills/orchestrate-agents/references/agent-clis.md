# Agent CLI matrix

Per-tool launch, headless, auto-approve, and resume flags for the four agent
CLIs the orchestrator can spawn. Always confirm a tool's current flags with
`<tool> --help`; CLIs change. Launch agents **bare and interactive** by default
so their own permission prompts stay on (the careful default). Add auto-approve
flags only when the run is explicitly opted into a less careful safety mode.

## Preference order

When a workstream does not pin a specific tool, pick in this order based on
what is installed: **1. claude**, **2. codex**, **3. copilot**, **4. gemini**.
`fleet.sh spawn ... auto` and `fleet.sh resolve_tool` already encode this.

## claude (Claude Code)

| Need | Command |
|------|---------|
| Interactive | `claude` (optionally `-n <name>`, `--model <m>`, `--effort <level>`, `--add-dir <d>`, `--agent <a>`) |
| Headless | `claude -p "<prompt>" [--output-format json]` |
| Auto-approve edits | `claude --permission-mode acceptEdits` |
| Full auto | `claude --dangerously-skip-permissions` |
| Resume | `claude -c` (continue) or `claude -r <id>` |

**Blocked-on-permission UI:** a bordered prompt ending in `Do you want to proceed?`
with numbered choices like `❯ 1. Yes`. Send `1` + Enter to approve once told to.

## codex (OpenAI Codex)

| Need | Command |
|------|---------|
| Interactive | `codex` (or `codex "<prompt>"` to seed the first turn) |
| Headless | `codex exec "<prompt>"` |
| Approval / sandbox | `codex --ask-for-approval <untrusted\|on-failure\|on-request\|never> --sandbox <mode>` |
| Full auto | `codex --full-auto` |
| Bypass everything | `codex --dangerously-bypass-approvals-and-sandbox` |
| Resume | `codex resume --last` |

**Note:** the npm package ships a vendored native binary; if `codex exec` errors
with `ENOENT` on the vendor path, the install is broken for this architecture.
Run `codex --version` in `doctor` follow-up before relying on it.

## copilot (GitHub Copilot CLI)

| Need | Command |
|------|---------|
| Interactive | `copilot` (optionally `--add-dir <d>`, `--effort <level>`, `--agent <a>`) |
| Headless | `copilot -p "<prompt>" --allow-all-tools` (non-interactive requires allow-all-tools) |
| Auto-approve tools | `copilot --allow-all-tools` |
| Full auto | `copilot --allow-all` (tools + paths + urls) |

**Blocked-on-permission UI:** asks to allow a tool/command; confirm per its prompt.

## gemini (Gemini CLI)

| Need | Command |
|------|---------|
| Interactive | `gemini` (positional query, `-m <model>`) |
| Prompt then interactive | `gemini -i "<prompt>"` |
| Headless | `gemini -p "<prompt>" [-o json]` |
| Auto-approve edits | `gemini --approval-mode auto_edit` |
| Full auto | `gemini --yolo` (or `--approval-mode yolo`) |
| Read-only / plan | `gemini --approval-mode plan` |
| Resume | `gemini -r latest` |

## State-detection patterns

`fleet.sh classify` greps the recent pane buffer for these. Extend the regexes in
the script if a tool's wording drifts.

- **needs-permission:** `Do you want to`, `Allow`, `Proceed?`, `(y/n)`, `[y/N]`,
  `❯ 1. Yes`, `Approve`, `requires approval`, `Continue?`.
- **error:** `Error`, `panic`, `Traceback`, `command not found`, `not logged in`,
  `Unauthorized`, `rate limit`, `quota exceeded`, `usage limit`, `context length`.
- **idle:** pane buffer unchanged for `FLEET_IDLE_SECS` (default 30s) and matching
  no prompt pattern. Often means done, or genuinely stuck. Verify with the
  transcript via `agentspec session export <tool> --last`.
