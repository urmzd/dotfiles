#!/usr/bin/env bash

call_bootstrap() {
	dirname="$(dirname "$1")"
	filename="$(basename $1)"
	cd "$dirname" || exit 1
	source "$filename" || exit 2
	cd ..
}

call_bootstrap "./install/bootstrap.sh"
call_bootstrap "./zsh/bootstrap.sh"
call_bootstrap "./nvim/bootstrap.sh"
call_bootstrap "./tmux/bootstrap.sh"
