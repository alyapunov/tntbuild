#!/bin/bash

if ! [[ -f test-run.patch ]]; then
    echo "Invalid working directory"
    exit 0
fi

./patch-test-run.sh -u
git submodule update --init --recursive
./patch-test-run.sh