#!/bin/bash

#cp node.ext2.bak node.ext2
bash ./scripts/image2rootfs.sh node alpine ext2

kernel=lupine-djw-kml
kernel=lupine-djw-nokml
kernel=microvm # works
kernel=no-dev-multi # works
kernel=node # works

firectl --firecracker-binary=$(pwd)/firecracker \
--kernel kernelbuild/${kernel}/vmlinux \
--root-drive=node.ext2 \
--vmm-log-fifo=firelog \
-d \
--kernel-opts="console=ttyS0 panic=1 init=/usr/local/bin/node"
#--kernel-opts="console=ttyS0 panic=1 init=/bin/sh"
#--kernel-opts="console=ttyS0 panic=1"
#--kernel-opts="console=ttyS0 panic=1 init=/usr/local/bin/docker-entrypoint.sh"
