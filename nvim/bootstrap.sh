#!/usr/bin/env bash

mkdir -p ~/.config/nvim
echo 'package.path = package.path .. ";~/dotfiles/nvim/src/?.lua"' > ~/.config/nvim/init.lua
echo 'require("custom_nvim")' > ~/.config/nvim/init.lua
