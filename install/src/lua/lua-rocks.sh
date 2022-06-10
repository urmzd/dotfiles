#!/usr/bin/env bash

sudo apt install build-essential libreadline-dev unzip
wget https://luarocks.org/releases/luarocks-3.8.0.tar.gz
tar zxpf luarocks-3.8.0.tar.gz
cd luarocks-3.8.0
./configure --with-lua-include=/usr/local/include
sudo make install
sudo rm -rf luarocks-3.8.0 luarocks-3.8.0.tar.gz

