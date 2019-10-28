#!/bin/bash

#cp golang.ext2.bak golang.ext2
bash ./scripts/image2rootfs.sh golang alpine ext2

kernel=lupine-djw-nokml++no-dev/

firectl --firecracker-binary=$(pwd)/firecracker \
--kernel kernelbuild/${kernel}/vmlinux \
--root-drive=golang.ext2 \
--vmm-log-fifo=firelog \
-d \
--kernel-opts="console=ttyS0 panic=1 init=/bin/sh"
#--kernel-opts="console=ttyS0 panic=1 init=/guest_start.sh"
