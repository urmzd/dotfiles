#!/usr/bin/env bash

sudo apt-get install tmux -y
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# For tmux-window-name
pip install libtmux
