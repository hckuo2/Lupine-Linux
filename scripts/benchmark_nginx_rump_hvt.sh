#!/bin/bash
source scripts/run-helper.sh
KERNEL=$1
BIN=${2:-nginx}

echo $KERNEL $BIN
for i in `seq 30`; do

    delete_tap $TAP
    create_current_tap

    sleep 3

    taskset -c 1 sudo ./scripts/solo5-hvt --disk=scripts/nginx-data.iso --net=tap100 scripts/nginx.hvt '{"cmdline":"bin/nginx.hvt -c /data/conf/nginx.conf","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"192.168.100.2","mask":"16"},"blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/data"}}' &
    vm=$!

    sleep 3
    taskset -c 2 ab -n 100000 -c 100 192.168.100.2/index.html >> nginx-rump.out
    pkill -9 solo5-hvt
done
