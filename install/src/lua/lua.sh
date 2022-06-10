#!/usr/bin/env bash

curl -R -O http://www.lua.org/ftp/lua-5.4.4.tar.gz
tar zxf lua-5.4.4.tar.gz
cd lua-5.4.4
make all test
sudo make install
rm -rf lua-5.4.4.tar.gz lua-5.4.4


