#!/usr/bin/sh

DOTFILES_DIR="$HOME/dotfiles"

SOURCE=(
	(".tmux.conf",),
	("nvim", "$HOME/config")
)

for dotfile in "${DOTFILES[@]}; do
	ln -sf "$DOTFILES_DIR/$dotfile" "$HOME/$dotfile"
done
