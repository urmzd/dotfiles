#!/usr/bin/env zsh

git clone gh:equalsraf/win32yank.git
cd win32yank
git checkout e229190
rustup target add x86_64-pc-windows-gnu
cargo build --release


