#!/bin/bash
# This file takes a config file and build a kernel base on the config
# The kernel built would be placed into a directory

KERNELBUILD="$(pwd)/kernelbuild"
LINUX="linux"
CONFIG=$1
FILENAME=$(basename $CONFIG)
BUILDDIR=$KERNELBUILD/${FILENAME%.*}
cp $CONFIG $LINUX/.config
make build-linux && \
    pushd $LINUX && \
    INSTALL_PATH=$BUILDDIR make install;
