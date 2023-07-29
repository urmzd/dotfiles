#!/usr/bin/env zsh

## RUN IN DOTFILES DIR
OH_MY_TMUX="$HOME/.oh-my-tmux"

git clone https://github.com/gpakosz/.tmux.git "$OH_MY_TMUX"
mkdir -p "~/.config/tmux"
ln -s "$OH_MY_TMUX/.tmux.conf" "~/.config/tmux/tmux.conf"
cp "$OH_MY_TMUX/.tmux.conf.local" "~/.config/tmux/tmux.conf.local"
