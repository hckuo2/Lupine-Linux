#!/bin/bash
source scripts/run-helper.sh
KERNEL=$1
BIN=${2:-/usr/local/bin/redis-server}
APP=redis

echo $KERNEL $BIN
for i in `seq 30`; do
    delete_tap $TAP
    create_current_tap
    touch /tmp/disk

    taskset -c 1 sudo ./scripts/solo5-hvt --disk=/tmp/disk --net=tap100 scripts/redis-server.hvt '{"cmdline":"redis-server.hvt","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"192.168.100.2","mask":"16"}}' &

    sleep 3
    taskset -c 2 redis-benchmark -h 192.168.100.2 -t get,set --csv >> redis-rump-hvt.out
    sudo pkill -9 solo5-hvt
done
