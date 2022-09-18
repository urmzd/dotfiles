#!/usr/bin/env bash

git clone https://github.com/sharkdp/fd.git
cd fd
cargo install --path .
cd ..
rm -rf fd
