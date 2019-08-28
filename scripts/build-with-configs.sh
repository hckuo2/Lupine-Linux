#!/bin/bash -e
# This file takes config files and build a kernel base on the config
# The kernel built would be placed into a directory

KERNELBUILD="$(pwd)/kernelbuild"
LINUX="linux"
CONFIGS=$@
DIRNAME=""
for config in $CONFIGS; do
    filename=$(basename $config)
    DIRNAME="$DIRNAME++${filename%.*}"
done
DIRNAME=${DIRNAME:2}
BUILDDIR=$KERNELBUILD/$DIRNAME

no() {
    while true; do
        echo "n"
    done
}

#(cd $LINUX && make mrproper)

mkdir -p $BUILDDIR
rm -f $LINUX/.config
for config in $CONFIGS; do
    cat $config >> $LINUX/.config
done
echo "Building kernel"
no | make -C linux oldconfig
make build-linux && \
    pushd $LINUX && \
    cp vmlinux $BUILDDIR && \
    INSTALL_PATH=$BUILDDIR make install;
echo "Linux size:" $(stat -c "%s" $BUILDDIR/vmlinux)
