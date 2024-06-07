#!/bin/bash

if ! [[ -f "$(pwd)/src/tarantool" ]] && ! [[ -f "$(pwd)/tarantool/src/tarantool" ]]; then
    echo "Must be run from tarantool build directory!"
    exit 1
fi

if [[ -d "$HOME/bin" ]]; then
    if [[ -f "$(pwd)/src/tarantool" ]]; then
        ln -s -f "$(pwd)/src/tarantool" "$HOME/bin/tarantool"
    elif [[ -f "$(pwd)/tarantool/src/tarantool" ]]; then
        ln -s -f "$(pwd)/tarantool/src/tarantool" "$HOME/bin/tarantool"
    fi

    if [[ -f "$(pwd)/extra/dist/tarantoolctl" ]]; then
        ln -s -f "$(pwd)/extra/dist/tarantoolctl" "$HOME/bin/tarantoolctl"
    elif [[ -f "$(pwd)/tarantool/extra/dist/tarantoolctl" ]]; then
        ln -s -f "$(pwd)/tarantool/extra/dist/tarantoolctl" "$HOME/bin/tarantoolctl"
    fi
else
    echo "$HOME/bin was not found"
fi

if [[ -d "$HOME/include" ]]; then
    if [[ -f "$(pwd)/src/module.h" ]]; then
        mkdir -p "$HOME/include/tarantool"
        ln -s -f "$(pwd)/src/module.h" "$HOME/include/tarantool/module.h"
    elif [[ -f $(pwd)/tarantool/src/module.h ]]; then
        mkdir -p "$HOME/include/tarantool"
        ln -s -f "$(pwd)/tarantool/src/module.h" "$HOME/include/tarantool/module.h"
    else
        echo "module.h was not found!"
    fi

    if [[ -f "$(pwd)/../third_party/luajit/src/lua.h" ]]; then
        ln -s -f "$(pwd)/../third_party/luajit/src" "$HOME/include/luajit"
    else
        echo "lua.h was not found!"
    fi
else
    echo "$HOME/include was not found"
fi
