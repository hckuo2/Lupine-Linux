#!/bin/bash
source scripts/run-helper.sh
tmp=`mktemp`
trap "rm $tmp" EXIT

if [ ! -f lat_syscall.ext2 ]; then
    pushd lat_syscall
    docker build -t lat_syscall:latest .
    popd
    ./scripts/image2rootfs.sh lat_syscall latest ext2
fi

run() {
    kernel=$1
    for i in 1 2 4 8 16 32 64 128 256 512 1024; do
        firectl --firecracker-binary=$(pwd)/firecracker \
            --kernel kernelbuild/lupine-djw-$kernel/vmlinux \
            --root-drive=lat_syscall.ext2 \
            --kernel-opts="console=ttyS0 noapic panic=-1 pci=off nomodules \
            init=/guest_sleeper.sh $i 30" \
            > $tmp 2>/dev/null

        printf "null %s %d %f %f\n" $kernel $i $(grep null $tmp | cut -d':' -f3 | stat)
        printf "read %s %d %f %f\n" $kernel $i $(grep read $tmp | cut -d':' -f3 | stat)
        printf "write %s %d %f %f\n" $kernel $i $(grep write $tmp | cut -d':' -f3 | stat)
    done 2> /dev/null
}

run kml++base
run nokml++base

