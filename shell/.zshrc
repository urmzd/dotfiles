ROOT="$HOME/dotfiles/shell"

# Configurations.
source "$ROOT/.zconf/wsl2.sh"
source "$ROOT/.zconf/user.sh"

# Utility Functions. 
source "$ROOT/.zconf/custom-functions.sh"

# Packages
source "$ROOT/.zconf/apt.sh"
source "$ROOT/.zconf/utils.sh"

# Terminal
source "$ROOT/.zconf/oh-my-zsh.sh"
source "$ROOT/.zconf/powerlevel10k.sh"

# Tools
source "$ROOT/.zconf/fzf.sh"

# Enable Completion.
source "$ROOT/.zconf/completion.sh"

# Node Package Manager.
source "$ROOT/.zconf/nvm.sh"

# NVIM
source "$ROOT/.zconf/nvim.sh"

# TMUX
source "$ROOT/.zconf/tmux.sh"

# Java
source "$ROOT/.zconf/java.sh"

# Go
source "$ROOT/.zconf/go.sh"

# Terraform
source "$ROOT/.zconf/terraform.sh"

# Lua
source "$ROOT/.zconf/lua.sh"

# Python Manager
source "$ROOT/.zconf/pyenv.sh"

# Node 
source "$ROOT/.zconf/node.sh"

# AWS
source "$ROOT/.zconf/aws.sh"

# Rust
source "$ROOT/.zconf/rust.sh"
