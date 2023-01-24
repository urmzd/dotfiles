#!/usr/bin/env bash

cd /tmp
rm -rf ripgrep
git clone https://github.com/BurntSushi/ripgrep.git
cd ripgrep
cargo install --path .
