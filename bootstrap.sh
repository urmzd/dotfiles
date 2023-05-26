#!/usr/bin/sh

sudo apt update -y && sudo apt upgrade -y

# Some basics.
./install/essentials.sh
./install/zsh.sh
./install/oh-my-zsh/oh-my-zsh.sh
./install/oh-my-zsh/powerlevel_10k.sh
./install/pyenv.sh
./install/nvm.sh
./install/nvim.sh
./install/tmux.sh
./install/fonts.sh

# Links
DOTFILES_DIR="$HOME/dotfiles"

ln -sf "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
ln -sf "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"
ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config"
ln -s "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
ln -s "$DOTFILES_DIR/alacritty.yml" "$HOME/.alacritty.yml"
