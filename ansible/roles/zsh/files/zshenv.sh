# Begin added by argcomplete
fpath=( /home/urmzd/.local/lib/python3.10/site-packages/argcomplete/bash_completion.d "${fpath[@]}" )
# End added by argcomplete

if [ -d "/mnt/c" ]; then
  VSCODE_PATH="/mnt/c/Users/urmzd/AppData/Local/Programs/Microsoft VS Code/bin"
  export PATH="$PATH:$VSCODE_PATH"
  export PATH="$PATH:/mnt/c/ProgramData/win32yank"
fi

export PYENV_ROOT="$HOME/.pyenv"

export PATH="/home/urmzd/.local/bin:$PATH"
export PATH="$PYENV_ROOT/bin:$PATH"

source "$HOME/.cargo/env"
