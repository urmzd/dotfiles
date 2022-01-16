#!/usr/bin/env zsh

RUSTUP_COMPLETION="$HOME/.oh-my-zsh/completions/_rustup" 
CARGO_COMPLETION="$HOME/.oh-my-zsh/completions/_cargo"

if [[ ! -f "$RUSTUP_COMPLETION" ]] 
then
  rustup completions zsh > "$RUSTUP_COMPLETION" 
fi

if [[ ! -f "$CARGO_COMPLETION" ]]
then
  rustup completions zsh cargo > "$CARGO_COMPLETION"
fi
