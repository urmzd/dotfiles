#!/usr/bin/env bash

NVIM_CONFIG_LOCATION="$HOME/.config/nvim"
NVIM_INIT_LOCATION="$NVIM_CONFIG_LOCATION/init.lua"

echo "$NVIM_CONFIG_LOCATION"
echo "$NVIM_INIT_LOCATION"

NVIM_PACKAGE_PATH="$HOME/dotfiles/nvim/src/?.lua"

mkdir -p "$NVIM_CONFIG_LOCATION"
echo 'package.path = package.path .. ";'"$NVIM_PACKAGE_PATH"'"' > "$NVIM_INIT_LOCATION"
echo 'require("custom_nvim")' >> "$NVIM_INIT_LOCATION"
