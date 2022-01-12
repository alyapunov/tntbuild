#!/bin/bash

if ! [[ -f test-run.patch ]]; then
    echo "Invalid working directory"
    exit 0
fi

if ! [[ -f luatest.patch ]]; then
    echo "Invalid working directory"
    exit 0
fi

if ! [[ -f ../test-run/.git ]]; then
    echo "test-run not inited, nothing to patch"
    exit 0
fi

if [[ $# -gt 1 ]] || ( [[ $# -eq 1 ]] && [[ $1 != '-u' ]] ); then
    echo "run '$0' or '$0 -u'"
    exit 0
fi

if [[ $1 == '-u' ]]; then
    cd ../test-run && git diff > ./patch.save && git checkout .
    cd ./lib/luatest && git diff > ./patch.save && git checkout .
else
    pth=`pwd`
    cd ../test-run && patch -f -p1 < $pth/test-run.patch
    rm ./lib/utils.py.rej > /dev/null 2>&1
    rm ./lib/utils.py.orig > /dev/null 2>&1
    cd ./lib/luatest && patch -f -p1 < $pth/luatest.patch
    rm ./luatest/assertions.lua.rej > /dev/null 2>&1
    rm ./luatest/assertions.lua.orig > /dev/null 2>&1
fi