#!/usr/bin/env bash
# fleet.sh -- deterministic tmux plumbing for orchestrating AI coding agents.
#
# A "fleet" is one tmux session. Windows group agents into workstreams.
# Panes hold one interactive agent CLI each (claude / codex / copilot / agy).
# Fleets are built survey-first: inspect what is already running (`survey`),
# adopt existing sessions/panes (`start` on an existing name, `adopt`), and
# only spawn new panes when nothing suitable exists.
#
# This script owns the fragile, repeated tmux incantations (send-keys timing,
# bracketed paste, capture, idle hashing, alerting). The orchestrator decides
# WHAT to spawn and WHEN to ping; this script makes those actions reliable.
#
# All commands print machine-readable lines (KEY=VALUE or TSV) so the caller
# can parse them. Errors go to stderr with a non-zero exit.

set -euo pipefail

# Agent CLIs install to these dirs (claude -> ~/.local/bin, npm CLIs ->
# ~/.local/npm/bin). Add them so tool resolution works even when invoked from a
# non-interactive shell whose PATH lacks them.
export PATH="$HOME/.local/bin:$HOME/.local/npm/bin:$PATH"

# --- config -----------------------------------------------------------------
# Tool preference when a requested tool is missing or "auto" is asked for.
PREF_ORDER=(claude codex copilot agy)
IDLE_SECS="${FLEET_IDLE_SECS:-30}"      # no pane change for this long => idle
CAPTURE_LINES="${FLEET_CAPTURE_LINES:-40}"
RUNDIR_BASE="${FLEET_RUNDIR:-${TMPDIR:-/tmp}/agent-fleet}"

# Patterns that mean an agent is blocked waiting for a human decision.
PERMISSION_RE='(Do you want to|Allow this|Allow command|Proceed\?|Approve|\(y/n\)|\[y/N\]|❯ 1\. Yes|Grant permission|requires? (your )?approval|Continue\?|press enter to confirm)'
# Patterns that mean something went wrong.
ERROR_RE='(^|[^a-zA-Z])(Error|ERROR|panic|Traceback|command not found|not logged in|authentication|Unauthorized|rate limit|quota exceeded|ECONNREFUSED|usage limit|context length)'

# --- helpers ----------------------------------------------------------------
die() { echo "fleet: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

rundir() { local f="$1"; printf '%s/%s' "$RUNDIR_BASE" "$f"; }

resolve_tool() {
  # Echo the binary to launch for a requested tool, falling back across
  # PREF_ORDER when the request is "auto" or the requested tool is absent.
  local want="$1"
  if [[ "$want" != "auto" ]] && have "$want"; then echo "$want"; return 0; fi
  if [[ "$want" != "auto" ]] && ! have "$want"; then
    echo "fleet: '$want' not on PATH, falling back" >&2
  fi
  for t in "${PREF_ORDER[@]}"; do
    if have "$t"; then echo "$t"; return 0; fi
  done
  die "no agent CLI found on PATH (looked for: ${PREF_ORDER[*]})"
}

require_session() {
  tmux has-session -t "$1" 2>/dev/null || die "no fleet named '$1' (run: fleet.sh start $1)"
}

control_pane() {
  # Find the control pane by its @fleet_role tag (immune to window renaming);
  # fall back to the session's first pane.
  local fleet="$1" p
  p=$(tmux list-panes -s -t "$fleet" -F '#{@fleet_role}	#{pane_id}' | awk -F'\t' '$1=="control"{print $2; exit}')
  [[ -n "$p" ]] && { echo "$p"; return; }
  tmux list-panes -s -t "$fleet" -F '#{pane_id}' | head -1
}

# --- commands ---------------------------------------------------------------

cmd_doctor() {
  echo "tmux=$(have tmux && tmux -V | awk '{print $2}' || echo MISSING)"
  for t in "${PREF_ORDER[@]}"; do echo "$t=$(have "$t" && echo ok || echo MISSING)"; done
  echo "agentspec=$(have agentspec && echo ok || echo MISSING)"
  local notifier=none
  if have osascript; then notifier=osascript; elif have notify-send; then notifier=notify-send; fi
  echo "notifier=$notifier"
}

fleet_settings() {
  # Display/alert settings shared by created and adopted fleets.
  local fleet="$1"
  tmux set -t "$fleet" pane-border-status top
  tmux set -t "$fleet" pane-border-format ' #{?@fleet_name,#{@fleet_name} [#{@fleet_tool}],#{pane_current_command}} '
  tmux set -t "$fleet" monitor-bell on
  # Explicitly set window names (new-window -n, rename-window) persist: the
  # user's shell hook skips windows tmux flags as manually named. We still
  # identify roles by pane options (@fleet_role), never by window or pane
  # NAME, as defense in depth.
  tmux set -t "$fleet" automatic-rename off 2>/dev/null || true
}

cmd_survey() {
  # survey [session] -- TSV inventory of every tmux pane (all sessions unless
  # filtered) so the orchestrator can understand what is ALREADY running
  # before creating or spawning anything. AGENT=yes is a heuristic: the
  # pane's foreground command matches a known agent CLI (npm-wrapped CLIs may
  # show as "node"; `capture` the pane to confirm). ROLE/NAME are fleet tags
  # left by a previous run; "-" means untagged.
  local filter="${1:-}"
  local agent_re; agent_re="^($(IFS='|'; echo "${PREF_ORDER[*]}"))$"
  printf 'SESSION\tWINDOW\tPANE\tCOMMAND\tAGENT\tROLE\tNAME\tCWD\n'
  # Conditional placeholders: empty tmux fields would collapse under tab-IFS
  # read (tabs are IFS whitespace), shifting every column after them.
  tmux list-panes -a -F '#{session_name}	#{window_name}	#{pane_id}	#{pane_current_command}	#{?@fleet_role,#{@fleet_role},-}	#{?@fleet_name,#{@fleet_name},-}	#{pane_current_path}' 2>/dev/null |
  while IFS=$'\t' read -r sess win pane cmdname role name cwd; do
    if [[ -n "$filter" && "$sess" != "$filter" ]]; then continue; fi
    agent=no
    [[ "$cmdname" =~ $agent_re ]] && agent=yes
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$sess" "$win" "$pane" "$cmdname" "$agent" "$role" "$name" "$cwd"
  done
}

cmd_start() {
  local fleet="${1:?usage: start <fleet>}"
  if tmux has-session -t "$fleet" 2>/dev/null; then
    # Adopt: an existing session becomes the fleet. Apply display settings and
    # the run dir, but do NOT touch panes -- tag agents explicitly via `adopt`.
    echo "fleet: '$fleet' already exists -- adopting it" >&2
    fleet_settings "$fleet"
    mkdir -p "$(rundir "$fleet")"
    echo "EXISTING=1"
  else
    tmux new-session -d -s "$fleet" -n control
    fleet_settings "$fleet"
    local ctrl; ctrl=$(tmux list-panes -t "$fleet:control" -F '#{pane_id}' | head -1)
    tmux set -p -t "$ctrl" @fleet_role control
    mkdir -p "$(rundir "$fleet")"
  fi
  echo "FLEET=$fleet"
  echo "ATTACH=tmux attach -t $fleet"
}

cmd_adopt() {
  # adopt <fleet> <pane> [--name N] [--tool T] -- tag an EXISTING pane as a
  # fleet agent so list/state/ping and guardians cover it, without restarting
  # whatever is running in it. The pane must live in the fleet's session
  # (`list` walks the session); adopt the session first via `start <session>`.
  local fleet="${1:?usage: adopt <fleet> <pane> [--name N] [--tool T]}"
  local pane="${2:?need pane id}"; shift 2
  local name="" tool=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name) name="$2"; shift 2;;
      --tool) tool="$2"; shift 2;;
      *) die "unknown adopt flag: $1";;
    esac
  done
  require_session "$fleet"
  local sess
  sess=$(tmux display-message -p -t "$pane" '#{session_name}' 2>/dev/null) || die "no such pane: $pane"
  [[ "$sess" == "$fleet" ]] || die "pane $pane is in session '$sess', not fleet '$fleet' (adopt that session: fleet.sh start $sess)"
  [[ -n "$tool" ]] || tool=$(tmux display-message -p -t "$pane" '#{pane_current_command}')
  [[ -n "$name" ]] || name="$tool"
  tmux set -p -t "$pane" @fleet_role agent
  tmux set -p -t "$pane" @fleet_name "$name"
  tmux set -p -t "$pane" @fleet_tool "$tool"
  mkdir -p "$(rundir "$fleet")"
  echo "PANE=$pane"
  echo "TOOL=$tool"
  echo "NAME=$name"
}

cmd_group() {
  local fleet="${1:?usage: group <fleet> <name>}" name="${2:?need window name}"
  require_session "$fleet"
  local win; win=$(tmux new-window -t "$fleet" -n "$name" -P -F '#{window_id}')
  echo "WINDOW=$win"
}

cmd_spawn() {
  # spawn <fleet> <window> <tool> [--name N] [--dir D]
  local fleet="${1:?usage: spawn <fleet> <window> <tool> [--name N] [--dir D]}"
  local window="${2:?need window}" tool="${3:?need tool}"; shift 3
  local name="" dir=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name) name="$2"; shift 2;;
      --dir)  dir="$2";  shift 2;;
      *) die "unknown spawn flag: $1";;
    esac
  done
  require_session "$fleet"
  local bin; bin=$(resolve_tool "$tool")
  [[ -n "$name" ]] || name="$bin"

  # Reuse a window's auto-created shell pane for its FIRST agent (tracked by a
  # marker keyed on window id, so it is deterministic regardless of boot timing);
  # split for every agent after that.
  local win_id pane marker
  win_id=$(tmux display-message -p -t "$fleet:$window" '#{window_id}')
  marker="$(rundir "$fleet")/win${win_id//@/}.init"
  if [[ ! -e "$marker" ]]; then
    pane=$(tmux list-panes -t "$fleet:$window" -F '#{pane_id}' | head -1)
    : >"$marker"
  else
    pane=$(tmux split-window -t "$fleet:$window" -P -F '#{pane_id}')
  fi
  tmux select-layout -t "$fleet:$window" tiled >/dev/null
  # Tag the pane: this is how list/ping/state find agents, immune to renaming.
  tmux set -p -t "$pane" @fleet_role agent
  tmux set -p -t "$pane" @fleet_name "$name"
  tmux set -p -t "$pane" @fleet_tool "$bin"

  local launch="$bin"
  [[ -n "$dir" ]] && launch="cd $(printf %q "$dir") && $launch"
  # clear, label, launch the CLI bare so its own permission prompts stay on.
  tmux send-keys -t "$pane" -l "$launch"
  tmux send-keys -t "$pane" Enter
  echo "PANE=$pane"
  echo "TOOL=$bin"
  echo "NAME=$name"
}

cmd_send() {
  # send <pane> <text...>  -- pastes text (bracketed, multiline-safe) then Enter.
  local pane="${1:?usage: send <pane> <text>}"; shift
  local text="$*"
  local buf="fleet-$$"
  printf '%s' "$text" | tmux load-buffer -b "$buf" -
  tmux paste-buffer -d -p -b "$buf" -t "$pane"
  sleep 0.4
  tmux send-keys -t "$pane" Enter
  echo "SENT=$pane"
}

cmd_capture() {
  local pane="${1:?usage: capture <pane> [lines]}" lines="${2:-$CAPTURE_LINES}"
  tmux capture-pane -p -t "$pane" -S "-$lines"
}

classify() {
  # classify <fleet> <pane> -- echoes one of:
  #   needs-permission | error | running | idle
  local fleet="$1" pane="$2"
  local tail; tail=$(tmux capture-pane -p -t "$pane" -S "-$CAPTURE_LINES" 2>/dev/null || true)
  if grep -Eq "$PERMISSION_RE" <<<"$tail"; then echo "needs-permission"; return; fi
  if grep -Eq "$ERROR_RE" <<<"$tail"; then echo "error"; return; fi

  # idle = capture unchanged for >= IDLE_SECS
  local hashfile; hashfile="$(rundir "$fleet")/$(tr -d '%$:.' <<<"$pane").hash"
  local now h; now=$(date +%s); h=$(printf '%s' "$tail" | cksum | awk '{print $1}')
  if [[ -f "$hashfile" ]]; then
    local prev_h prev_t; IFS=' ' read -r prev_h prev_t <"$hashfile"
    if [[ "$h" == "$prev_h" ]]; then
      if (( now - prev_t >= IDLE_SECS )); then echo "idle"; return; fi
      echo "running"; return
    fi
  fi
  printf '%s %s\n' "$h" "$now" >"$hashfile"
  echo "running"
}

cmd_list() {
  # list <fleet> -- TSV: window  name  tool  state  pane  (agent panes only)
  local fleet="${1:?usage: list <fleet>}"
  require_session "$fleet"
  printf 'WINDOW\tNAME\tTOOL\tSTATE\tPANE\n'
  while IFS=$'\t' read -r role win pane name tool; do
    [[ "$role" == "agent" ]] || continue
    local state; state=$(classify "$fleet" "$pane")
    printf '%s\t%s\t%s\t%s\t%s\n' "$win" "${name:-?}" "${tool:-?}" "$state" "$pane"
  done < <(tmux list-panes -s -t "$fleet" -F '#{@fleet_role}	#{window_name}	#{pane_id}	#{@fleet_name}	#{@fleet_tool}')
}

cmd_state() {
  local fleet="${1:?usage: state <fleet> <pane>}" pane="${2:?need pane}"
  require_session "$fleet"
  classify "$fleet" "$pane"
}

cmd_ping() {
  # ping <fleet> <message> [pane]  -- fire all alert channels.
  local fleet="${1:?usage: ping <fleet> <message> [pane]}" msg="${2:?need message}" pane="${3:-}"
  # 1. in-chat: stderr line the orchestrator relays to the user.
  echo "PING[$fleet]: $msg" >&2
  # 2. macOS notification (or notify-send on Linux).
  if have osascript; then
    osascript -e "display notification \"${msg//\"/\'}\" with title \"agent-fleet: $fleet\" sound name \"Submarine\"" >/dev/null 2>&1 || true
  elif have notify-send; then
    notify-send "agent-fleet: $fleet" "$msg" || true
  fi
  # 3. terminal bell + status line on the relevant pane (or the control pane).
  local target="$pane"
  [[ -n "$target" ]] || target=$(control_pane "$fleet")
  tmux display-message -t "$target" "🔔 $msg" 2>/dev/null || true
  local tty; tty=$(tmux display-message -p -t "$target" '#{pane_tty}' 2>/dev/null || true)
  [[ -n "$tty" && -w "$tty" ]] && printf '\a' >"$tty" 2>/dev/null || true
  echo "PINGED=$fleet"
}

cmd_dashboard() {
  # dashboard <fleet> -- turn the control pane into a live status table.
  local fleet="${1:?usage: dashboard <fleet>}"
  require_session "$fleet"
  local self; self=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/fleet.sh
  local pane; pane=$(control_pane "$fleet")
  tmux send-keys -t "$pane" -l "while true; do clear; echo '== fleet: $fleet =='; date; echo; $(printf %q "$self") list $fleet | column -t -s \$'\t'; sleep 3; done"
  tmux send-keys -t "$pane" Enter
  echo "DASHBOARD=$pane"
}

cmd_attach() { echo "tmux attach -t ${1:?usage: attach <fleet>}"; }

cmd_kill() {
  local fleet="${1:?usage: kill <fleet>}"
  tmux kill-session -t "$fleet" 2>/dev/null && rm -rf "$(rundir "$fleet")" || true
  echo "KILLED=$fleet"
}

# --- dispatch ---------------------------------------------------------------
have tmux || die "tmux is required"

cmd="${1:-}"; shift || true
case "$cmd" in
  doctor)    cmd_doctor "$@";;
  survey)    cmd_survey "$@";;
  start)     cmd_start "$@";;
  adopt)     cmd_adopt "$@";;
  group)     cmd_group "$@";;
  spawn)     cmd_spawn "$@";;
  send)      cmd_send "$@";;
  capture)   cmd_capture "$@";;
  list)      cmd_list "$@";;
  state)     cmd_state "$@";;
  ping)      cmd_ping "$@";;
  dashboard) cmd_dashboard "$@";;
  attach)    cmd_attach "$@";;
  kill)      cmd_kill "$@";;
  ""|help|-h|--help)
    cat >&2 <<'EOF'
fleet.sh -- tmux orchestration for AI coding agents

  doctor                         check tmux, agent CLIs, agentspec, notifier
  survey [session]               TSV inventory of ALL tmux panes (run this first)
  start <fleet>                  create detached session, or adopt an existing one
  adopt <fleet> <pane> [--name N] [--tool T]
                                 tag an existing pane as a fleet agent (no restart)
  group <fleet> <name>           add a window (workstream group)
  spawn <fleet> <window> <tool> [--name N] [--dir D]
                                 launch an agent CLI in a new pane (tool: auto|claude|codex|copilot|agy)
  send  <pane> <text...>         paste text into a pane and submit
  capture <pane> [lines]         print recent pane output
  list  <fleet>                  TSV of every agent + inferred state
  state <fleet> <pane>           classify one pane: running|idle|needs-permission|error
  ping  <fleet> <msg> [pane]     alert on all channels (chat/notification/bell/status)
  dashboard <fleet>              turn control pane into a live status table
  attach <fleet>                 print the attach command (do not attach from the orchestrator)
  kill  <fleet>                  tear down the session
EOF
    exit 1;;
  *) die "unknown command: $cmd (try: fleet.sh help)";;
esac
