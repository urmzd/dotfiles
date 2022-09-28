#!/usr/bin/env zsh

git clone git@github.com:equalsraf/win32yank.git
cd win32yank
git checkout e229190
rustup target add x86_64-pc-windows-gnu
cargo build --release --target x86_64-pc-windows-gnu
sudo cp target/x86_64-pc-windows-gnu/release/win32yank.exe /usr/local/bin
