#!/usr/bin/env bash

# Ensure source files are held in temporary directory.
cd /tmp

# Cleanup existing downloads.
rm -rf fd

# Get source files.
git clone https://github.com/sharkdp/fd.git

# Open directory.
cd fd

# Install
cargo install --path .

# Add completions.
mkdir -p ~/.oh-my-zsh/completions
cp contrib/completion/_fd ~/.oh-my-zsh/completions/_fd
