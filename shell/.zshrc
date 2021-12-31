# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Configurations.
source ~/.zconf/wsl2.sh
source ~/.zconf/user.sh

# Utility Functions. 
source ~/.zconf/custom-functions.sh

# Packages
source ~/.zconf/apt.sh

# Terminal
source ~/.zconf/oh-my-zsh.sh
source ~/.zconf/powerlevel10k.sh

# Tools
source ~/.zconf/fzf.sh

# Enable Completion.
source ~/.zconf/completion.sh

# Node Package Manager.
source ~/.zconf/nvm.sh

# NVIM
source ~/.zconf/nvim.sh
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
