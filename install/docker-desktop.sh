#!/usr/bin/env bash

wget https://desktop.docker.com/linux/main/amd64/docker-desktop-4.14.1-amd64.deb -O docker-desktop.deb

sudo apt-get update && apt-get install ./docker-desktop.deb -y

rm -rf ./docker-desktop.deb
