#~/bin/bash

show_snippet() {
    echo ""
    echo "Code snippet:"
    echo "ffi = require('ffi') ffi.cdef('int is_debug;') ffi.C.is_debug = 1"
}

usage() {
    echo "Inject or remove global int is_debug variable to tarantool source."
    echo "Usage:"
    echo "$0 set               - inject variable"
    echo "$0 set make          - inject variable and make"
    echo "$0 unset             - remove injection"
    echo "$0 unset make        - remove injection and make"
    echo "$0 <anything else    - show current status and this help"
    show_snippet
    exit 0
}

error() {
   echo "$@" 1>&2
   exit 1
}

do_show=false
do_set=false
do_unset=false
do_make=false

if [[ $# > 2 ]]; then
    usage
fi

if [[ $# == 0 ]]; then
    do_show=true
else
    if [[ "$1" == "set" ]]; then
        do_set=true
    elif [[ "$1" == "unset" ]]; then
        do_unset=true
    else
        usage
    fi
    if [[ $# == 2 ]]; then
        if [[ "$2" == "make" ]]; then
            do_make=true
        else
            usage
        fi
    fi
fi

builddir=`realpath .`

if ! [[ -f "$builddir/CMakeCache.txt" ]]; then
    error "Tarantool build was not found in '$builddir'"
fi
line=$(grep "^tarantool_SOURCE_DIR:STATIC=" "$builddir/CMakeCache.txt")
if ! [[ "$line" =~ ^tarantool_SOURCE_DIR:STATIC=(.*)$ ]]; then
    error "Tarantool build was not found in '$builddir'"
fi
sourcedir="${BASH_REMATCH[1]}"

exports_file="$sourcedir/extra/exports"
main_file="$sourcedir/src/main.cc"
exports_string="is_debug"
main_string="int is_debug;"

if ! [[ -f "$exports_file" ]]; then
    error "Exports file was not found: $exports_file"
fi
if ! [[ -f "$main_file" ]]; then
    error "Main file was not found: $main_file"
fi

if grep -xq "$exports_string" "$exports_file"; then
    is_in_exports=true
    echo "'$exports_string' IS in exports file"
else
    is_in_exports=false
    echo "'$exports_string' is NOT in exports file"
fi

if grep -xq "$main_string" "$main_file"; then
    is_in_main=true
    echo "'$main_string' IS in main file"
else
    is_in_main=false
    echo "'$main_string' is NOT in main file"
fi

if [[ $do_show == true ]]; then
    show_snippet
    exit 0
fi

echo "--------------"

if [[ $do_set == true ]]; then
    if [[ $is_in_exports == false ]]; then
        echo "$exports_string" >> "$exports_file"
        echo "'$exports_string' was injected to exports file"
    fi
    if [[ $is_in_main == false ]]; then
        echo "$main_string" >> "$main_file"
        echo "'$main_string' was injected to main file"
    fi
else
    if [[ $is_in_exports == true ]]; then
        grep -vx "$exports_string" "$exports_file" > ./is_debug.tmp
        mv ./is_debug.tmp "$exports_file"
        echo "'$exports_string' was removed from exports file"
    fi
    if [[ $is_in_main == true ]]; then
        grep -vx "$main_string" "$main_file" > ./is_debug.tmp
        mv ./is_debug.tmp "$main_file"
        echo "'$main_string' was removed from main file"
    fi
fi

if [[ $do_make == true ]]; then
    make -j
fi

show_snippet

echo "Done"
