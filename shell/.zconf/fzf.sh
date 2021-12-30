queryinstallpackage "fzf" 1
queryinstallpackage "ripgrep" 1

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# FZF Settings.
export FZF_DEFAULT_COMMAND="fd --type f"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
