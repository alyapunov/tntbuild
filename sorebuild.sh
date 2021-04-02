#!/bin/bash
cd ./so
TNT="../.."
MP="$TNT/src/lib/msgpuck"
LJ="$TNT/third_party/luajit/src"
I="-I. -I../src -I../third_party/luajit/src -I$LJ -I$MP"
gcc ./so.c "$MP/msgpuck.c" "$MP/hints.c" $I --shared -fPIC -o ../echo.so
gcc ./so.c "$MP/msgpuck.c" "$MP/hints.c" $I --shared -fPIC -o ../vshard/storage.so
