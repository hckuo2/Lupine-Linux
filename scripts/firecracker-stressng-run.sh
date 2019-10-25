#!/bin/bash

#cp node.ext2.bak node.ext2
bash ./scripts/image2rootfs.sh moul-kernel-builder latest ext2

kernel=lupine-djw-kml
kernel=lupine-djw-nokml
kernel=microvm # works
kernel=node # works
kernel=microvm # works
kernel=no-dev
kernel=no-dev-multi
kernel=no-dev-with-smp
kernel=no-dev-multi++smp

firectl --firecracker-binary=$(pwd)/firecracker \
--kernel kernelbuild/${kernel}/vmlinux \
--root-drive=moul-kernel-builder.ext2 \
--vmm-log-fifo=firelog \
--ncpus=1 \
--memory=8192 \
-d \
--kernel-opts="console=ttyS0 panic=1 init=/guest_start.sh"
#--kernel-opts="console=ttyS0 panic=1 init=/bin/bash"
#--kernel-opts="console=ttyS0 panic=1 init=/usr/local/bin/node"
#--kernel-opts="console=ttyS0 panic=1"
#--kernel-opts="console=ttyS0 panic=1 init=/usr/local/bin/docker-entrypoint.sh"
