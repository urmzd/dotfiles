#!/usr/bin/env zsh

LINK="https://go.dev/dl/go1.18.2.linux-amd64.tar.gz"
FILE_NAME="go1.18.2.linux-amd64.tar.gz"
curl -L $LINK --output $FILE_NAME

tar -xzf $FILE_NAME
sudo mv go /usr/local/bin
trash $FILE
