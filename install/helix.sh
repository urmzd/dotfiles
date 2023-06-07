#!/usr/bin/env bash

RUSTFLAGS="-C target-feature=-crt-static"

cd /tmp
git clone https://github.com/helix-editor/helix
cd helix

#cargo install --path helix-term --locked

hx -g fetch
hx -g build

