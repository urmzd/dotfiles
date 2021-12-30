NVM_DIR="$HOME/.nvm"

if [[ ! -d "$NVM_DIR" ]]
then
  git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
  cd "$NVM_DIR"
  git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
fi

export "$NVM_DIR";
source "$NVM_DIR/nvm.sh"
source "$NVM_DIR/bash_completion"
