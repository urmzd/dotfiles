#!/usr/bin/env zsh

ROOT="$HOME/dotfiles/zsh"

# Configurations.
source "$ROOT/zconf/user.sh"

# Utility Functions. 
source "$ROOT/zconf/custom-functions.sh"

# Terminal
source "$ROOT/zconf/oh-my-zsh.sh"
source "$ROOT/zconf/powerlevel10k.sh"

# Tools
source "$ROOT/zconf/fzf.sh"

## Gradle
#source "$ROOT/zconf/gradle.sh"

# Enable Completion.
source "$ROOT/zconf/completion.sh"

# Node Package Manager.
source "$ROOT/zconf/nvm.sh"
source "$ROOT/zconf/node.sh"

# NVIM
source "$ROOT/zconf/nvim.sh"

## Java
#source "$ROOT/zconf/java.sh"

# Terraform
# source "$ROOT/zconf/terraform.sh"

# Lua
# source "$ROOT/zconf/lua.sh"

# Python
source "$ROOT/zconf/pyenv.sh"
source "$ROOT/zconf/python.sh"

# AWS
source "$ROOT/zconf/aws.sh"

# Rust
source "$ROOT/zconf/rust.sh"

# BFG 
source "$ROOT/zconf/bfg.sh"

# OMZ
source "$HOME/.oh-my-zsh/oh-my-zsh.sh"

# GoLang
source "$ROOT/zconf/go.sh"
