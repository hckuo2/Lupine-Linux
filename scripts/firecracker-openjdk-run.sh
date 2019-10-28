#!/bin/bash

#cp openjdk.ext2.bak openjdk.ext2
bash ./scripts/image2rootfs.sh openjdk alpine ext2

kernel=lupine-djw-nokml++no-dev/

firectl --firecracker-binary=$(pwd)/firecracker \
--kernel kernelbuild/${kernel}/vmlinux \
--root-drive=openjdk.ext2 \
--vmm-log-fifo=firelog \
-d \
--kernel-opts="console=ttyS0 panic=1 init=/guest_start.sh"
#--kernel-opts="console=ttyS0 panic=1 init=/bin/sh"
