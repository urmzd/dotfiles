#!/usr/bin/env bash

sudo apt-get install dconf-cli uuid-runtime -y

# clone the repo into "$HOME/src/gogh"
mkdir -p "$HOME/src"
cd "$HOME/src"
git clone https://github.com/Gogh-Co/Gogh.git gogh
cd gogh

# necessary in the Gnome terminal on ubuntu
export TERMINAL=gnome-terminal

# Enter themes dir
cd themes

# install themes
./gruvbox.sh
