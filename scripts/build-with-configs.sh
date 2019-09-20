#!/bin/bash -e
# This file takes config files and build a kernel base on the config
# The kernel built would be placed into a directory

unpatch-linux() {
    pushd $LINUX
    git reset --hard HEAD
    git clean -fd
    popd
}

KERNELBUILD="$(pwd)/kernelbuild"
LINUX="linux"
if [[ $1 == "nopatch" ]]; then
    echo "You are using nopatch kernel source"
    NOPATCH="true"
    unpatch-linux
    shift
else
    make patch-linux || true
fi

CONFIGS=$@
DIRNAME=""
for config in $CONFIGS; do
    filename=$(basename $config)
    DIRNAME="$DIRNAME++${filename%.*}"
done
DIRNAME=${DIRNAME:2}
BUILDDIR=$KERNELBUILD/$DIRNAME

rm -f $LINUX/.config || true
for config in $CONFIGS; do
    cat $config >> $LINUX/.config
done

echo "Building kernel"
yes no | make -C $LINUX oldconfig
make build-linux
mkdir -p $BUILDDIR
pushd $LINUX && \
    cp vmlinux $BUILDDIR && \
    INSTALL_PATH=$BUILDDIR make install;
echo "Linux size:" $(stat -c "%s" $BUILDDIR/vmlinux)

