#!/usr/bine/env zsh

[[ -d "$HOME/.oh-my-zsh" ]] || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

if [[ -d "$HOME/.oh-my-zsh" ]]
then
  # Path to your oh-my-zsh installation.
  export ZSH="$HOME/.oh-my-zsh"

  ZSH_THEME="powerlevel10k/powerlevel10k"

  plugins=(git vi-mode fzf-zsh-plugin) 

  source $ZSH/oh-my-zsh.sh
fi
