#!/bin/bash

APP=php
TAG=alpine
KERNEL=lupine-djw-nokml++php
INIT="/guest_start.sh"

FS=$APP.ext2

sudo killall firecracker
scripts/build-with-configs.sh nopatch configs/lupine-djw-nokml.config configs/php.config

rm -f $FS
scripts/image2rootfs.sh $APP $TAG ext2 >/dev/null 

sudo firectl --firecracker-binary=$(pwd)/firecracker \
     --kernel kernelbuild/$KERNEL/vmlinux \
     --root-drive=$FS \
     --vmm-log-fifo=firelog \
     -d \
     --kernel-opts="panic=-1 pci=off reboot=k tsc=reliable ipv6.disable=1 console=ttyS0 init=$INIT"

#qemu-system-x86_64 -enable-kvm -no-reboot -kernel linux/arch/x86_64/boot/bzImage -drive "file=$FS,format=raw" -nographic -nodefaults -serial stdio -append "panic=-1 console=ttyS0 root=/dev/sda rw loglevel=15 nokaslr init=/bin/ash"
