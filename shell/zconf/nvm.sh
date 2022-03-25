NVM_DIR="$HOME/.nvm"
NVM_COMPLETION="$HOME/.nvm/bash_completion"

if [[ ! -d "$NVM_DIR" ]]
then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | zsh
fi

source "$NVM_COMPLETION"
