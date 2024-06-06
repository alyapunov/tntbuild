#!/bin/bash

BLD=$(pwd)
TNT=$(pwd)/..

MP="$TNT/src/lib/msgpuck"
LJ="$TNT/third_party/luajit/src"
I="-I./so -I$BLD/src -I$LJ -I$MP"

gcc ./so/so.c "$MP/msgpuck.c" "$MP/hints.c" $I --shared -fPIC -o ./echo.so
gcc ./so/so.c "$MP/msgpuck.c" "$MP/hints.c" $I --shared -fPIC -o ./vshard/storage.so
