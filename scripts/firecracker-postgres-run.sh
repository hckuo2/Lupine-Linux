#!/bin/bash

APP=postgres
TAG=alpine
KERNEL=lupine-djw-nokml++postgres
INIT="/guest_start.sh"

FS=$APP.ext2

sudo killall firecracker
scripts/build-with-configs.sh nopatch configs/lupine-djw-nokml.config configs/apps/postgres.config

rm -f $FS
scripts/image2rootfs.sh $APP $TAG ext2 >/dev/null 

sudo firectl --firecracker-binary=$(pwd)/firecracker --kernel kernelbuild/$KERNEL/vmlinux --tap-device=tap100/AA:FC:00:00:00:01 --root-drive=$FS --kernel-opts="panic=-1 pci=off reboot=k tsc=reliable ipv6.disable=1 console=ttyS0 init=$INIT"

