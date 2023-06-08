#!/usr/bin/env bash

git clone https://github.com/neovim/neovim
cd neovim
git checkout nightly
make CMAKE_BUILD_TYPE=Release
sudo make install
cd ..
rm -rf neovim
