#!/usr/bin/env bash

git clone https://github.com/BurntSushi/ripgrep.git
cd ripgrep
cargo install --path .
cd ..
rm -rf ripgrep
