#!/bin/bash

#cp python.ext2.bak python.ext2
bash ./scripts/image2rootfs.sh python alpine ext2

kernel=lupine-djw-nokml

firectl --firecracker-binary=$(pwd)/firecracker \
--kernel kernelbuild/${kernel}/vmlinux \
--root-drive=python.ext2 \
--vmm-log-fifo=firelog \
-d \
--kernel-opts="console=ttyS0 panic=1 init=/usr/local/bin/python"
#--kernel-opts="console=ttyS0 panic=1 init=/bin/sh"
#--kernel-opts="console=ttyS0 panic=1"
#--kernel-opts="console=ttyS0 panic=1 init=/usr/local/bin/docker-entrypoint.sh"
