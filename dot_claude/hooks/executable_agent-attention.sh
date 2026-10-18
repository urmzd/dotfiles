#!/usr/bin/env bash
# Flags the tmux pane running this Claude Code session while the agent is
# waiting on you, so the window shows an icon in the status line.
#
#   agent-attention.sh set    Notification, Stop: agent needs input or is done
#   agent-attention.sh clear  UserPromptSubmit, PostToolUse, SessionEnd
#
# The flag is the pane option @agent_waiting; tmux.conf renders it per window.
# Outside tmux this is a no-op. It never fails, so it cannot block Claude.
cat >/dev/null
[ -n "${TMUX_PANE:-}" ] && command -v tmux >/dev/null 2>&1 || exit 0
case "${1:-}" in
    set)   tmux set-option -p -t "$TMUX_PANE" @agent_waiting 1 ;;
    clear) tmux set-option -pu -t "$TMUX_PANE" @agent_waiting ;;
esac 2>/dev/null
exit 0
