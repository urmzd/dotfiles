#!/usr/bin/env zsh

sudo apt-get install curl git mercurial make binutils bison gcc build-essential
zsh < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)

exec zsh

gvm install go1.4 -B
gvm use go1.4
export GOROOT_BOOTSTRAP=$GOROOT
gvm install go1.19
