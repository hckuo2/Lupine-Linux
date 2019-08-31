#!/bin/bash -e

KERNEL=$1
firectl --firecracker-binary=$(pwd)/firecracker \
    --kernel kernelbuild/microvm-paravirt+kml/vmlinux \
    --tap-device=tap100/AA:FC:00:00:00:01 \
    --root-drive=redis.ext2 \
    --kernel-opts="console=ttyS0 noapic  panic=-1 pci=off nomodules rw init=/bin/ash"
