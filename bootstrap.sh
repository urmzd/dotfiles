#!/usr/bin/env bash

call_bootstrap() {
	parent="$(dirname $1)"
	echo $parent
	cd "$parent"
	source "$1"
	cd ..
}

call_bootstrap "./install/bootstrap.sh"
call_bootstrap "./zsh/bootstrap.sh"
call_bootstrap "./nvim/bootstrap.sh"
call_bootstrap "./tmux/bootstrap.sh"
