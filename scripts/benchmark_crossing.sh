#!/bin/bash -e
source scripts/run-helper.sh
KERNEL=$1
shift
BIN=$@
DISK=crossing.ext2
rm -f $DISK
./scripts/image2rootfs.sh crossing latest ext2

echo $KERNEL $BIN
for i in `seq 10`; do
    sleep 3
    taskset -c 1 firectl --firecracker-binary=$(pwd)/firecracker \
        --kernel $KERNEL \
        --root-drive=$DISK \
        --kernel-opts="panic=-1 pci=off reboot=k tsc=reliable quiet 8250.nr_uarts=1 ipv6.disable=1 init=$BIN"
done
