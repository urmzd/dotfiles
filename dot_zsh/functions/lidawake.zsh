# lidawake [on|off|status]: keep a Mac awake with the lid closed, so tmux
# sessions and agents stay reachable over SSH (see the "remote" bundle).
# Uses `pmset disablesleep`, which stays set across reboots until turned off.
lidawake() {
  if [[ "$(uname)" != Darwin ]]; then
    echo "lidawake: macOS only" >&2
    return 1
  fi
  case "${1:-status}" in
    on)  sudo pmset -a disablesleep 1 && echo "lidawake: on (lid close will not sleep)" ;;
    off) sudo pmset -a disablesleep 0 && echo "lidawake: off" ;;
    status)
      if pmset -g | grep -q 'SleepDisabled[[:space:]]*1'; then
        echo "lidawake: on"
      else
        echo "lidawake: off"
      fi
      ;;
    *) echo "usage: lidawake [on|off|status]" >&2; return 2 ;;
  esac
}
