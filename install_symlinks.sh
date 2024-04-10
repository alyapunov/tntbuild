#!/bin/bash

if ! [[ -f $(pwd)/src/tarantool ]] && ! [[ -f $(pwd)/tarantool/src/tarantool ]]; then
    echo "Must be run from tarantool build dirctory!"
    exit 1
fi

if [[ -f $(pwd)/src/tarantool ]]; then
    ln -s -f $(pwd)/src/tarantool ~/bin/tarantool
elif [[ -f $(pwd)/tarantool/src/tarantool ]]; then
    ln -s -f $(pwd)/tarantool/src/tarantool ~/bin/tarantool
fi

if [[ -f $(pwd)/extra/dist/tarantoolctl ]]; then
    ln -s -f $(pwd)/extra/dist/tarantoolctl ~/bin/tarantoolctl
elif [[ -f $(pwd)/tarantool/extra/dist/tarantoolctl ]]; then
    ln -s -f $(pwd)/tarantool/extra/dist/tarantoolctl ~/bin/tarantoolctl
fi


