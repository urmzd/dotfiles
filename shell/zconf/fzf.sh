if [[ ! -d "$HOME/.fzf" ]] 
then
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install
fi

# FIXME - ADD FDFIND support

queryinstallpackage "ripgrep" 1

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
