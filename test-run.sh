#!/bin/bash
MY_BUILD_DIR="$(pwd)"
for i in {1..16}; do
    cd "$MY_BUILD_DIR/test" && "$MY_BUILD_DIR/../test/test-run.py" "--builddir=$MY_BUILD_DIR" --force $@
    cd "$MY_BUILD_DIR"

    if ! [[ -f /tmp/luatest_auto.txt ]]; then
        break
    fi

    if ! ./luatest_auto.sh; then
        break
    fi
done
