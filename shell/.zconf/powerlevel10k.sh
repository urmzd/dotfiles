#!/usr/bin/env zsh

POWERLEVEL10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

if [[ ! -d "$POWERLEVEL10K_DIR" ]] 
then
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$POWERLEVEL10K_FILE"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
