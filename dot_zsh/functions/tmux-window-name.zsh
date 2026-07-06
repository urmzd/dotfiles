# Smart tmux window naming - updates on each prompt, but never overwrites a
# manual name. tmux flags manually named windows by setting window-level
# automatic-rename off (rename-window, new-window -n, prefix+,); we skip those.
# Our own rename trips the same flag, so we clear it right after (the window
# still inherits the global automatic-rename off). prefix+R releases a manual
# name back to auto-naming.
# Always target $TMUX_PANE: untargeted tmux commands act on the session's
# focused window, not the window this prompt belongs to.
_update_tmux_window_name() {
    [[ -n "$TMUX" && -n "$TMUX_PANE" ]] || return 0
    local script="$HOME/.config/tmux/scripts/smart-window-name.sh"
    [[ -x "$script" ]] || return 0
    [[ -n "$(tmux show-options -wqv -t "$TMUX_PANE" automatic-rename)" ]] && return 0
    tmux rename-window -t "$TMUX_PANE" "$("$script")"
    tmux set-option -uw -t "$TMUX_PANE" automatic-rename
}
precmd_functions+=(_update_tmux_window_name)
