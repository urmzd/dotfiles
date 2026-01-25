# Smart tmux window naming - updates on each prompt
_update_tmux_window_name() {
    if [[ -n "$TMUX" ]]; then
        local script="$HOME/.config/tmux/scripts/smart-window-name.sh"
        if [[ -x "$script" ]]; then
            tmux rename-window "$("$script")"
        fi
    fi
}
precmd_functions+=(_update_tmux_window_name)
