#!/bin/bash
# Tmux + Neovim Debug Helper
# This script facilitates debugging workflows across Tmux and Neovim
# Usage: debug_tmux_helper.sh [action] [args...]

set -e

NVIM_SESSION_NAME="nvim-debug"
DEBUG_LOG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/debug.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    echo -e "${BLUE}[DEBUG HELPER]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$DEBUG_LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$DEBUG_LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# ============================================================================
# CORE FUNCTIONS
# ============================================================================

# Launch Neovim in a new Tmux window for debugging
launch_nvim_debug_window() {
    local file="${1:-.}"
    local line="${2:-1}"

    if ! tmux has-session -t "$NVIM_SESSION_NAME" 2>/dev/null; then
        tmux new-session -d -s "$NVIM_SESSION_NAME" -x 200 -y 50 \
            "nvim +'call cursor($line, 1)' '$file'"
        success "Launched Neovim debug session in tmux: $NVIM_SESSION_NAME"
    else
        tmux send-keys -t "$NVIM_SESSION_NAME" "nvim +'call cursor($line, 1)' '$file'" Enter
        success "Opened $file at line $line in existing Neovim session"
    fi
}

# Attach to existing Neovim debug session
attach_nvim_debug() {
    if tmux has-session -t "$NVIM_SESSION_NAME" 2>/dev/null; then
        tmux attach-session -t "$NVIM_SESSION_NAME"
        success "Attached to Neovim debug session"
    else
        error "No active Neovim debug session. Launch one with: debug_tmux_helper.sh launch <file>"
    fi
}

# Set breakpoint in Neovim session from Tmux
set_breakpoint_remote() {
    local file="$1"
    local line="$2"

    if [ -z "$file" ] || [ -z "$line" ]; then
        error "Usage: debug_tmux_helper.sh breakpoint <file> <line>"
        return 1
    fi

    if ! tmux has-session -t "$NVIM_SESSION_NAME" 2>/dev/null; then
        error "No Neovim session active. Start with: debug_tmux_helper.sh launch"
        return 1
    fi

    # Send command to Neovim session
    tmux send-keys -t "$NVIM_SESSION_NAME" \
        ":edit $file | call cursor($line, 1) | execute 'silent! normal! <leader>dP'" Enter

    success "Breakpoint set at $file:$line"
}

# Start debug session in Neovim
start_debug_session() {
    local file="${1:-.}"

    if ! tmux has-session -t "$NVIM_SESSION_NAME" 2>/dev/null; then
        launch_nvim_debug_window "$file"
    fi

    # Send debug start command
    tmux send-keys -t "$NVIM_SESSION_NAME" "<leader>dd" Enter
    success "Started debug session for $file"
}

# Stop debug session
stop_debug_session() {
    if ! tmux has-session -t "$NVIM_SESSION_NAME" 2>/dev/null; then
        warning "No active Neovim session"
        return 0
    fi

    tmux send-keys -t "$NVIM_SESSION_NAME" "<leader>dK"
    success "Stopped debug session"
}

# Restart debug session
restart_debug_session() {
    if ! tmux has-session -t "$NVIM_SESSION_NAME" 2>/dev/null; then
        error "No Neovim session active"
        return 1
    fi

    tmux send-keys -t "$NVIM_SESSION_NAME" "<leader>dR"
    success "Restarted debug session"
}

# Show available breakpoints
show_breakpoints() {
    if ! tmux has-session -t "$NVIM_SESSION_NAME" 2>/dev/null; then
        error "No Neovim session active"
        return 1
    fi

    tmux send-keys -t "$NVIM_SESSION_NAME" "<leader>d?"
    success "Listed breakpoints in Neovim"
}

# Kill entire Neovim session
kill_nvim_session() {
    if tmux has-session -t "$NVIM_SESSION_NAME" 2>/dev/null; then
        tmux kill-session -t "$NVIM_SESSION_NAME"
        success "Killed Neovim debug session"
    else
        warning "No active Neovim session"
    fi
}

# Show status of debug session
show_status() {
    if tmux has-session -t "$NVIM_SESSION_NAME" 2>/dev/null; then
        echo -e "${GREEN}Session Active:${NC} $NVIM_SESSION_NAME"
        tmux list-windows -t "$NVIM_SESSION_NAME" | head -5
    else
        echo -e "${YELLOW}No active session${NC}"
    fi
}

# Show help
show_help() {
    cat << 'EOF'
Tmux + Neovim Debug Helper

USAGE:
  debug_tmux_helper.sh [COMMAND] [ARGS]

COMMANDS:
  launch <file> [line]       Launch Neovim in new Tmux session, open file at line
  attach                     Attach to active Neovim debug session
  start <file>               Start debugging a file
  stop                       Stop current debug session
  restart                    Restart current debug session
  breakpoint <file> <line>   Set breakpoint remotely in Neovim
  list                       Show active breakpoints
  status                     Show debug session status
  kill                       Kill the entire Neovim session
  log                        Show debug log
  help                       Show this help message

ENVIRONMENT:
  NVIM_SESSION_NAME          Tmux session name (default: nvim-debug)
  DEBUG_LOG_FILE             Log file location

EXAMPLES:
  # Launch Neovim and open a file
  debug_tmux_helper.sh launch ~/my_project/app.py

  # Open file at specific line
  debug_tmux_helper.sh launch ~/my_project/app.py 42

  # Start debugging
  debug_tmux_helper.sh start ~/my_project/app.py

  # Set breakpoint from Tmux
  debug_tmux_helper.sh breakpoint ~/my_project/app.py 15

  # Attach to running session
  debug_tmux_helper.sh attach

  # Stop debugging
  debug_tmux_helper.sh stop

  # Show current status
  debug_tmux_helper.sh status

WORKFLOW:
  1. In Tmux, launch Neovim:
     $ debug_tmux_helper.sh launch myfile.py

  2. In another Tmux pane/window:
     $ debug_tmux_helper.sh start myfile.py

  3. Set breakpoints remotely:
     $ debug_tmux_helper.sh breakpoint myfile.py 42

  4. Or attach to Neovim and use <leader>d* commands:
     $ debug_tmux_helper.sh attach

  5. View log:
     $ debug_tmux_helper.sh log
EOF
}

# Show debug log
show_log() {
    if [ -f "$DEBUG_LOG_FILE" ]; then
        tail -50 "$DEBUG_LOG_FILE"
    else
        echo "No debug log found at $DEBUG_LOG_FILE"
    fi
}

# ============================================================================
# MAIN DISPATCHER
# ============================================================================

main() {
    local command="${1:-help}"

    case "$command" in
        launch)
            launch_nvim_debug_window "$2" "${3:-1}"
            ;;
        attach)
            attach_nvim_debug
            ;;
        start)
            start_debug_session "$2"
            ;;
        stop)
            stop_debug_session
            ;;
        restart)
            restart_debug_session
            ;;
        breakpoint)
            set_breakpoint_remote "$2" "$3"
            ;;
        list)
            show_breakpoints
            ;;
        status)
            show_status
            ;;
        kill)
            kill_nvim_session
            ;;
        log)
            show_log
            ;;
        help|--help|-h|\?)
            show_help
            ;;
        *)
            error "Unknown command: $command"
            echo "Use 'debug_tmux_helper.sh help' for available commands"
            exit 1
            ;;
    esac
}

# Initialize debug log
mkdir -p "$(dirname "$DEBUG_LOG_FILE")"
touch "$DEBUG_LOG_FILE"

# Run main
main "$@"
