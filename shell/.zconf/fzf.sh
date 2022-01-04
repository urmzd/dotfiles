if [[ ! -d "$HOME/.fzf" ]] 
then
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install
fi

queryinstallpackage "ripgrep" 1
queryinstallpackage "fd-find" 

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#FZF Settings.
export FZF_DEFAULT_COMMAND="fdfind --type f"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
