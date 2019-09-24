#!/bin/bash
source scripts/run-helper.sh
ITER=30
SERVER_CPUS=$(seq -s "," 0 2 $(nproc))
CLIENT_CPUS=$(seq -s "," 1 2 $(nproc))
run-benchmark() {
    KML=$1
    KERNEL=$2
    TYPE=$3
    LOG=benchmark-logs/$(echo $KERNEL | cut -d/ -f3).$TYPE.log
    echo $LOG
    rm -f $LOG
    # we do not need to use regular path for nokml because they run on an
    # unpatch kernel already.
    if [[ $TYPE == "redis" ]]; then
        if [[ $KML == "kml" ]]; then
            BIN=/trusted/redis-server
        else BIN=/usr/local/bin/redis-server
        fi
    elif [[ $TYPE == "nginx" ]]; then
        if [[ $KML == "kml" ]]; then
            BIN=/trusted/nginx
        else
            BIN=/usr/sbin/nginx
        fi
    fi
    yes | ./scripts/image2rootfs.sh $TYPE alpine ext2
    for i in `seq $ITER`; do
        cp $TYPE.ext2 $TYPE.ext2.disposible
        {
            while ! grep -q "APP START" vm.stdout; do
                sleep 1
            done
            sleep 3
            if [[ $TYPE == "redis" ]]; then
                taskset -c "$CLIENT_CPUS" redis-benchmark --csv -h 192.168.100.2 \
                    -t get,set >> $LOG 2>&1
            elif [[ $TYPE == "nginx" ]]; then
                taskset -c "$CLIENT_CPUS" ab -n 100000 -c 100 \
                192.168.100.2/index.html >> $LOG 2>&1
            fi
            pkill firecracker
            rm vm.stdout
        } &
        taskset -c "$SERVER_CPUS" firectl --firecracker-binary=$(pwd)/firecracker \
            --kernel $KERNEL \
            --tap-device=tap100/AA:FC:00:00:00:01 \
            --root-drive=$TYPE.ext2.disposible \
            --ncpus=1 --memory=512 \
            --kernel-opts="console=ttyS0 panic=-1 pci=off tsc=reliable ipv6.disable=1 init=/guest_start.sh $BIN" > vm.stdout
        wait
    done
}

run-benchmark nokml ./kernelbuild/microvm/vmlinux nginx
# run-benchmark kml ./kernelbuild/lupine-djw-kml++nginx/vmlinux nginx
# run-benchmark kml ./kernelbuild/lupine-djw-kml-tiny++nginx/vmlinux nginx
# run-benchmark nokml ./kernelbuild/lupine-djw-nokml++nginx/vmlinux nginx
# run-benchmark nokml ./kernelbuild/lupine-djw-nokml-tiny++nginx/vmlinux nginx

run-benchmark nokml ./kernelbuild/microvm/vmlinux redis
# run-benchmark kml ./kernelbuild/lupine-djw-kml++redis/vmlinux redis
# run-benchmark kml ./kernelbuild/lupine-djw-kml-tiny++redis/vmlinux redis
# run-benchmark nokml ./kernelbuild/lupine-djw-nokml++redis/vmlinux redis
# run-benchmark nokml ./kernelbuild/lupine-djw-nokml-tiny++redis/vmlinux redis

for f in benchmark-logs/*.log; do
    if [[ $f == *"redis"* ]]; then
        printf "Redis-Get $(basename $f | sed 's/djw-//' | sed 's/++redis//' | sed 's/.log//') "
        grep GET $f | cut -d',' -f2 | tr -d '"' | st | tail -n1
        printf "Redis-Set $(basename $f | sed 's/djw-//' | sed 's/++redis//' | sed 's/.log//') "
        grep SET $f | cut -d',' -f2 | tr -d '"' | st | tail -n1
    fi
    if [[ $f == *"nginx"* ]]; then
        printf "Nginx $(basename $f | sed 's/djw-//' | sed 's/++nginx//' | sed 's/.log//') "
        grep Request $f | awk '{print $4}' | st | tail -n1
    fi
done
