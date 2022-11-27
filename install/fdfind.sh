#!/usr/bin/env bash

git clone https://github.com/sharkdp/fd.git
cd fd
cargo install --path .
cp contrib/completion/_fd ~/.oh-my-zsh/completions/_fd
cd ..
trash fd
