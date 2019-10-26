#!/bin/bash
source scripts/run-helper.sh

#cp mongo.ext2.bak mongo.ext2
bash ./scripts/image2rootfs.sh mongo latest ext2

kernel=no-dev-multi
kernel=microvm
kernel=lupine-djw-nokml
kernel=lupine-djw-kml++mongo

delete_tap $TAP
create_current_tap

firectl --firecracker-binary=$(pwd)/firecracker \
--kernel kernelbuild/${kernel}/vmlinux \
--root-drive=mongo.ext2 \
--tap-device=tap100/AA:FC:00:00:00:01 \
--vmm-log-fifo=firelog \
-d \
--kernel-opts="console=ttyS0 panic=1 init=/guest_start.sh"
#--kernel-opts="console=ttyS0 panic=1 init=/bin/sh"
#--kernel-opts="console=ttyS0 panic=1"
#--kernel-opts="console=ttyS0 panic=1 init=/usr/local/bin/mongo"
#--kernel-opts="console=ttyS0 panic=1 init=/usr/local/bin/docker-entrypoint.sh"
