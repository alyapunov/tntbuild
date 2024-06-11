#!/bin/bash

if [[ $# -ne 0 ]] && [[ "$1" != "-u" ]] && [[ "$1" != "--uninstall" ]]; then
    echo "Usage ./$(basename $0) [-u|--uninstall]"
    exit 0
fi

source=$(dirname $(realpath $0))
target="$HOME/bin/tntbuild.sh"

is_uninstall=false
if [[ "$1" == "-u" ]] || [[ "$1" == "--uninstall" ]]; then
    if [[ -f "$target" ]]; then
        rm "$target"
    else
        echo "Installed file '$target' was not found: nothing to uninstall"
    fi
    exit 0
fi

cat > "$target" << 'EOM'
#!/bin/bash

src="TEMPLATE_SOURCE"

valid="--uninstall\n-u\n--light\n-l\n"
if [[ $# -gt 1 ]] || ! echo -e "$valid" | fgrep -x -- "$1" > /dev/null; then
    echo "Usage ./$(basename $0) [-u|--uninstall|-l|--light]"
    exit 0
fi

is_uninstall=false
if [[ "$1" == "-u" ]] || [[ "$1" == "--uninstall" ]]; then
    is_uninstall=true
fi

is_light=false
if [[ "$1" == "-l" ]] || [[ "$1" == "--light" ]]; then
    is_light=true
fi

if [[ $is_uninstall == false ]] && [[ $is_light == false ]]; then
    if [ ! -f '../CMakeLists.txt' ]; then
        echo 'Should be run from subfolder of tarantool!'
        exit 0
    fi

    if ! grep -i 'project(tarantool' ../CMakeLists.txt > /dev/null; then
        echo 'Should be run from subfolder of tarantool!'
        exit 0
    fi
fi

full_files=(
    "so"

    "test-run.sh"
    "luatest_auto.sh"
    "sorebuild.sh"
    "cmake_options.txt"
    "install_symlinks.sh"
    "is_debug.sh"
    "sub.sh"
    "patch-test-run.sh"
    "test-run.patch"
    "luatest.patch"

    "my.lua"
    "test_run.lua"
    "txn_proxy.lua"
    "luatest.lua"
    "run.lua"
    "reprun.lua"
    "rep.lua"
)

light_files=(
    "test-run.sh"
    "luatest_auto.sh"
    "cmake_options.txt"
    "sub.sh"
    "patch-test-run.sh"
    "test-run.patch"
    "luatest.patch"
)

files=("${full_files[@]}")
if [[ $is_light == true ]]; then
    files=("${light_files[@]}")
fi

if [[ $is_uninstall == false ]]; then
    if ! [[ -d ./vshard ]]; then
        mkdir vshard
    fi
    for f in ${files[@]}; do
        ln -s -f "$src/$f"
    done
    if [[ $is_light == false ]]; then
        echo "Also it could be a good idea to run './install_symlinks.sh'"
    fi
else
    for f in ${files[@]}; do
        if [[ -L "./$f" ]]; then
            rm "./$f"
        fi
    done
    if [[ -f "./vshard/storage.so" ]]; then
        rm "./vshard/storage.so"
    fi
    if [[ -d "./vshard" ]]; then
        rm -d "./vshard"
    fi
fi
EOM
sed -i "s+TEMPLATE_SOURCE+$source+g" "$target"
chmod 755 "$target"
