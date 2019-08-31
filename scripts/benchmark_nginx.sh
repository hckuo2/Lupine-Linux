#!/bin/bash
source scripts/run-helper.sh
KERNEL=$1
BIN=${2:-nginx}

echo $KERNEL $BIN
for i in `seq 30`; do
    delete_tap $TAP
    create_current_tap
    rm -f nginx.ext2
    sleep 3
    ./scripts/image2rootfs.sh nginx alpine ext2
    taskset -c 1 firectl --firecracker-binary=$(pwd)/firecracker \
        --kernel $KERNEL \
        --tap-device=tap100/AA:FC:00:00:00:01 \
        --root-drive=nginx.ext2 \
        --kernel-opts="panic=-1 pci=off reboot=k tsc=reliable quiet 8250.nr_uarts=0 ipv6.disable=1 init=/guest_start.sh $BIN" &
    vm=$!
    taskset -c 2 ab -n 100000 -c 100 192.168.100.2/index.html
    pkill -9 firecracker
done
