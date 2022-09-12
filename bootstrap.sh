#!/usr/bin/env bash

function call_bootstrap() {
	parent="$(dirname $1)"
	cd "$parent"
	source "$1"
	cd ..
}

call_bootstrap "./install/bootstrap.sh"
call_bootstrap "./zsh/bootstrap.sh"
call_bootstrap "./nvim/bootstrap.sh"
call_bootstrap "./tmux/bootstrap.sh"
