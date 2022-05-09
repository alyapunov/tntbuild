#!/bin/bash

if ! [[ -f $(pwd)/src/tarantool ]]; then
    echo "Must be run from tarantool build dirctory!"
    exit 1
fi

if ! grep -i 'project(tarantool' ../CMakeLists.txt > /dev/null; then
    echo "Must be run from tarantool build dirctory!"
    exit 1
fi

ln -s -f $(pwd)/src/tarantool ~/bin/tarantool
ln -s -f $(pwd)/extra/dist/tarantoolctl ~/bin/tarantoolctl

