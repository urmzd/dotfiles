#!/usr/bin/env zsh

export ZSH="$HOME/.oh-my-zsh"

# Install OhMyZsh
[[ -d "$ZSH" ]] || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Plugins
FZF_ZSH_PLUGIN="$ZSH/custom/plugins/fzf-zsh-plugin"
[[ -d "$FZF_ZSH_PLUGIN" ]] || git clone https://github.com/unixorn/fzf-zsh-plugin.git "$FZF_ZSH_PLUGIN"

# Configurations
if [[ -d "$HOME/.oh-my-zsh" ]]
then
  export ZSH="$ZSH"

  # Path to your oh-my-zsh installation.
  ZSH_THEME="powerlevel10k/powerlevel10k"

  plugins=(git vi-mode fzf-zsh-plugin) 

  source "$ZSH/oh-my-zsh.sh"
fi
