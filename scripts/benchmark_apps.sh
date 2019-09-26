#!/bin/bash
source scripts/run-helper.sh
ITER=30
SERVER_CPUS=$(seq -s "," 0 2 $(nproc))
CLIENT_CPUS=$(seq -s "," 1 2 $(nproc))
run-benchmark() {
    TYPE=$1
    KML=$2
    TINY=$3
    KERNEL=$4
    APP=$5
    LOG=benchmark-logs/$TYPE.$KML.$TINY.$APP.log
    echo $LOG
    rm -f $LOG
    if [[ $TYPE == "vm" ]]; then
        if [[ $APP == "redis" ]]; then
            if [[ $KML == "kml" ]]; then
                BIN=/trusted/redis-server
            else
                BIN=/usr/local/bin/redis-server
            fi
        elif [[ $APP == "nginx" ]]; then
            if [[ $KML == "kml" ]]; then
                BIN=/trusted/nginx
            else
                BIN=/usr/sbin/nginx
            fi
        fi
        yes | ./scripts/image2rootfs.sh $APP alpine ext2
        for i in `seq $ITER`; do
            {
                while ! grep -q "APP START" server.stdout; do
                    sleep 1
                done
                sleep 3
                if [[ $APP == "redis" ]]; then
                    taskset -c "$CLIENT_CPUS" redis-benchmark --csv -h 192.168.100.2 \
                        -t get,set >> $LOG 2>&1
                elif [[ $APP == "nginx" ]]; then
                    taskset -c "$CLIENT_CPUS" ab -n 100000 -c 100 \
                    192.168.100.2/index.html >> $LOG 2>&1
                fi
                pkill firecracker
                rm server.stdout
            } &
            cp $APP.ext2 $APP.ext2.disposible
            taskset -c "$SERVER_CPUS" firectl --firecracker-binary=$(pwd)/firecracker \
                --kernel $KERNEL \
                --tap-device=tap100/AA:FC:00:00:00:01 \
                --root-drive=$APP.ext2.disposible \
                --ncpus=1 --memory=512 \
                --kernel-opts="console=ttyS0 panic=-1 pci=off tsc=reliable ipv6.disable=1 init=/guest_start.sh $BIN" > server.stdout
            wait
        done
    elif [[ $TYPE == "osv" ]]; then
        for i in `seq $ITER`; do
            {
                while ! grep -q "Booted up" server.stdout; do
                    sleep 1
                done
                sleep 3
                if [[ $APP == "redis" ]]; then
                    taskset -c "$CLIENT_CPUS" redis-benchmark --csv -h 172.16.0.2 \
                        -t get,set >> $LOG 2>&1
                elif [[ $APP == "nginx" ]]; then
                    taskset -c "$CLIENT_CPUS" ab -n 100000 -c 1 \
                    172.16.0.2/index.html >> $LOG 2>&1
                fi
                sudo pkill firecracker
                rm server.stdout
            } &

            pushd osv
            if [[ $APP == "redis" ]]; then
                ./scripts/build -j`nproc` image=redis-memonly
            elif [[ $APP == "nginx" ]]; then
                ./scripts/build -j`nproc` image=nginx
            fi
            sudo FIRECRACKER_PATH=../firecracker taskset -c $SERVER_CPUS \
                ./scripts/firecracker.py  -c 1 -m 512M -n > ../server.stdout
            popd
        done
    fi
}

# run-benchmark vm nokml notiny ./kernelbuild/microvm/vmlinux nginx
# run-benchmark vm kml notiny ./kernelbuild/lupine-djw-kml++nginx/vmlinux nginx
# run-benchmark vm kml tiny ./kernelbuild/lupine-djw-kml-tiny++nginx/vmlinux nginx
# run-benchmark vm nokml notiny ./kernelbuild/lupine-djw-nokml++nginx/vmlinux nginx
# run-benchmark vm nokml tiny ./kernelbuild/lupine-djw-nokml-tiny++nginx/vmlinux nginx

# run-benchmark vm nokml notiny ./kernelbuild/microvm/vmlinux redis
# run-benchmark vm kml notiny ./kernelbuild/lupine-djw-kml++redis/vmlinux redis
# run-benchmark vm kml tiny ./kernelbuild/lupine-djw-kml-tiny++redis/vmlinux redis
# run-benchmark vm nokml notiny ./kernelbuild/lupine-djw-nokml++redis/vmlinux redis
# run-benchmark vm nokml tiny ./kernelbuild/lupine-djw-nokml-tiny++redis/vmlinux redis

# run-benchmark osv dummy dummy nginx
# run-benchmark osv dummy dummy redis

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
