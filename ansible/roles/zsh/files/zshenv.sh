# Begin added by argcomplete
fpath=( /home/urmzd/.local/lib/python3.10/site-packages/argcomplete/bash_completion.d "${fpath[@]}" )
# End added by argcomplete

VSCODE_PATH="/mnt/c/Users/urmzd/AppData/Local/Programs/Microsoft VS Code/bin"

export PYENV_ROOT="$HOME/.pyenv"

export PATH="/home/urmzd/.local/bin:$PATH"
export PATH="$PYENV_ROOT/bin:$PATH"
export PATH="$PATH:$VSCODE_PATH"

source "$HOME/.cargo/env"
