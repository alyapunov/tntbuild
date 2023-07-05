#!/bin/bash
MY_BUILD_DIR="$(pwd)"

UNIT_TESTS="$(pwd)/test/unit/*.test"
dropped_unit_tests=()
for file in $UNIT_TESTS; do
    if [[ -x "$file" ]]; then
        make -q $(basename "$file") 2> /dev/null
        rc=$?
        if [[ $rc == 2 ]]; then
            dropped_unit_tests+=($(basename "$file"))
            rm "$file"
        fi
    fi
done

RED='\033[0;31m'
NC='\033[0m' # No Color
if ! [[ ${#dropped_unit_tests[@]} == 0 ]]; then
    echo "The following unit tests were dropped since they are not in targets"
    for file in ${dropped_unit_tests[@]}; do
        printf "${RED}$file${NC}\n"
    done
fi

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
