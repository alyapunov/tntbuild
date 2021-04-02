#!/bin/bash
MY_BUILD_DIR="$(pwd)"
cd $MY_BUILD_DIR/test && $MY_BUILD_DIR/../test/test-run.py --builddir=$MY_BUILD_DIR --vardir=$MY_BUILD_DIR/test/var --force $@
