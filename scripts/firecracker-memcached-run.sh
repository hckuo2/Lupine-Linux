#!/bin/bash
source scripts/run-helper.sh

#cp node.ext2.bak node.ext2
bash ./scripts/image2rootfs.sh memcached latest ext2

kernel=lupine-djw-kml
kernel=lupine-djw-nokml
kernel=microvm # works
kernel=node # works
kernel=microvm # works
kernel=no-dev
kernel=no-dev-multi
kernel=no-dev-with-smp
kernel=lupine-djw-kml++memcached

delete_tap $TAP
create_current_tap

firectl --firecracker-binary=$(pwd)/firecracker \
--kernel kernelbuild/${kernel}/vmlinux \
--root-drive=memcached.ext2 \
--tap-device=tap100/AA:FC:00:00:00:01 \
--vmm-log-fifo=firelog \
--ncpus=1 \
--memory=8192 \
-d \
--kernel-opts="console=ttyS0 panic=1 init=/guest_start.sh"
#--kernel-opts="console=ttyS0 panic=1 init=/bin/bash"
#--kernel-opts="console=ttyS0 panic=1 init=/usr/local/bin/node"
#--kernel-opts="console=ttyS0 panic=1"
#--kernel-opts="console=ttyS0 panic=1 init=/usr/local/bin/docker-entrypoint.sh"
