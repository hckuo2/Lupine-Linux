#!/bin/bash

LOG=bootlog
KERNEL=$1
total=0

rm measure-boot.ext2
[ -f measure-boot.ext2 ] || ./scripts/image2rootfs.sh measure-boot latest ext2

for i in $(seq 30); do
    echo "" > $LOG
    taskset -c 1 firectl --firecracker-binary=$(pwd)/firecracker \
        --kernel $KERNEL \
        --root-drive=measure-boot.ext2  \
        --firecracker-log=$LOG \
        --kernel-opts="panic=-1 pci=off reboot=k tsc=reliable quiet 8250.nr_uarts=0 ipv6.disable=1 init=/measure-boot-fc" 2>/dev/null

    grep "Guest-boot-time" $LOG | awk '{print $12}'
done | st
