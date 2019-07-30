#!/bin/bash
source scripts/run-helper.sh
KERNEL=$1
BIN=${2:-/usr/local/bin/redis-server}
APP=redis

echo $KERNEL $BIN
for i in `seq 30`; do
    delete_tap $TAP
    create_current_tap
    rm -f $APP.ext2
    ./scripts/image2rootfs.sh $APP alpine ext2
    taskset -c 1 firectl --firecracker-binary=$(pwd)/firecracker \
        --kernel $KERNEL \
        --tap-device=tap100/AA:FC:00:00:00:01 \
        --root-drive=$APP.ext2 \
        --kernel-opts="panic=-1 pci=off reboot=k tsc=reliable quiet 8250.nr_uarts=0 ipv6.disable=1 init=/guest_start.sh $BIN" &
    sleep 3
    taskset -c 2 redis-benchmark -h 192.168.100.2 -t get,set --csv
    pkill -9 firecracker
done
