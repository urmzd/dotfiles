#!/usr/bin/env zsh

CARGO_PATH="$HOME/.cargo/bin"

if [[ ! -d $CARGO_PATH ]]
then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi

export PATH="$PATH:$HOME/.cargo/bin"

COMPLETIONS_FOLDER="$HOME/.oh-my-zsh/completions"
RUSTUP_COMPLETION="$COMPLETIONS_FOLDER/_rustup" 
CARGO_COMPLETION="$COMPLETIONS_FOLDER/_cargo"

if [[ ! -d $COMPLETIONS_FOLDER ]]
then
  mkdir -p "$COMPLETIONS_FOLDER"
fi

if [[ ! -f "$RUSTUP_COMPLETION" ]] 
then
  rustup completions zsh > "$RUSTUP_COMPLETION" 
fi

if [[ ! -f "$CARGO_COMPLETION" ]]
then
  rustup completions zsh cargo > "$CARGO_COMPLETION"
fi
