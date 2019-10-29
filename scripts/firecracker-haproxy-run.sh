#!/bin/bash
source scripts/run-helper.sh

#cp haproxy.ext2.bak haproxy.ext2
bash ./scripts/image2rootfs.sh haproxy latest ext2

kernel=no-dev-multi
kernel=lupine-djw-nokml
kernel=microvm
kernel=lupine-djw-kml++haproxy

delete_tap $TAP
create_current_tap

firectl --firecracker-binary=$(pwd)/firecracker \
--kernel kernelbuild/${kernel}/vmlinux \
--root-drive=haproxy.ext2 \
--tap-device=tap100/AA:FC:00:00:00:01 \
--vmm-log-fifo=firelog \
--ncpus=1 \
--memory=8192 \
-d \
--kernel-opts="console=ttyS0 panic=1 init=/guest_start.sh"
#--kernel-opts="console=ttyS0 panic=1 init=/bin/sh"
#--kernel-opts="console=ttyS0 panic=1"
#--kernel-opts="console=ttyS0 panic=1 init=/usr/local/bin/haproxy"
#--kernel-opts="console=ttyS0 panic=1 init=/usr/local/bin/docker-entrypoint.sh"
