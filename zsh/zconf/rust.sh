CARGO_PATH="$HOME/.cargo/bin"

export PATH="$PATH:$HOME/.cargo/bin"

rustup completions zsh > ~/.oh-my-zsh/completions/_rustup
rustup completions zsh cargo > ~/.oh-my-zsh/completions/_cargo
