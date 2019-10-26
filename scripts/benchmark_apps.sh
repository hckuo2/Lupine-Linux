#!/bin/bash
source scripts/run-helper.sh
ITER=35
encode-kernel-name() {
    basename $(dirname $1) | sed 's/-djw//' \
        | sed 's/++redis//' \
        | sed 's/++nginx//'
}
run-benchmark() {
    TYPE=$1
    KML=$2
    TINY=$3
    KERNEL=$4
    APP=$5
    APPTYPE=$6 # this is for nginx only
    LOG=benchmark-logs/$APP$APPTYPE.$(encode-kernel-name $KERNEL).log
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
                    if [[ $APPTYPE == "conn" ]]; then
                        taskset -c "$CLIENT_CPUS" ab -n 100000 -c 100 \
                            192.168.100.2/index.html >> $LOG 2>&1
                    elif [[ $APPTYPE == "sess" ]]; then
                        taskset -c "$CLIENT_CPUS" ab -k -n 100000 -c 100 \
                            192.168.100.2/index.html >> $LOG 2>&1
                    fi
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
                    if [[ $APPTYPE == "conn" ]]; then
                        taskset -c "$CLIENT_CPUS" ab -n 100000 -c 100 \
                            172.16.0.2/index.html >> $LOG 2>&1
                    elif [[ $APPTYPE == "sess" ]]; then
                        taskset -c "$CLIENT_CPUS" ab -k -n 100000 -c 100 \
                            172.16.0.2/index.html >> $LOG 2>&1
                    fi
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
    elif [[ $TYPE == "rump-hvt" ]]; then
        delete_current_tap
        create_current_tap
        sleep 1
        for i in `seq $ITER`; do
            if [[ $APP == "redis" ]]; then
                touch /tmp/disk
                taskset -c $SERVER_CPUS sudo ./scripts/solo5-hvt \
                    --disk=/tmp/disk --net=tap100 scripts/redis-server.hvt \
                    '{"cmdline":"redis-server.hvt","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"192.168.100.2","mask":"16"}}' &

                sleep 3
                taskset -c $CLIENT_CPUS redis-benchmark -h 192.168.100.2 -t get,set \
                    --csv >> $LOG 2>&1
            elif [[ $APP == "nginx" ]]; then
                taskset -c $SERVER_CPUS sudo ./scripts/solo5-hvt \
                    --disk=scripts/nginx-data.iso \
                    --net=tap100 scripts/nginx.hvt '{"cmdline":"bin/nginx.hvt -c /data/conf/nginx.conf","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"192.168.100.2","mask":"16"},"blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/data"}}' &
                                    sleep 3
                if [[ $APPTYPE == "conn" ]]; then
                    taskset -c $CLIENT_CPUS ab -n 100000 -c 100 \
                        -c 100 192.168.100.2/index.html >> $LOG 2>&1
                elif [[ $APPTYPE == "sess" ]]; then
                    taskset -c $CLIENT_CPUS ab -n 100000 -c 100 \
                        -c 100 192.168.100.2/index.html >> $LOG 2>&1
                fi
            fi
            sudo pkill -9 solo5-hvt
        done
    fi
}

for apptype in conn sess; do
    # run-benchmark vm nokml notiny ./kernelbuild/microvm/vmlinux nginx $apptype
    # run-benchmark vm kml notiny ./kernelbuild/lupine-djw-kml++nginx/vmlinux nginx $apptype
    # run-benchmark vm kml tiny ./kernelbuild/lupine-djw-kml-tiny++nginx/vmlinux nginx $apptype
    # run-benchmark vm nokml notiny ./kernelbuild/lupine-djw-nokml++nginx/vmlinux nginx $apptype
    # run-benchmark vm nokml tiny ./kernelbuild/lupine-djw-nokml-tiny++nginx/vmlinux nginx $apptype
    # run-benchmark vm dummy dummy ./kernelbuild/microvm/vmlinux nginx $apptype
    run-benchmark rump-hvt dummy dmmy rump-hvt/dummy nginx $apptype
    # run-benchmark osv dummy dummy osv/dummy nginx $apptype
done
# run-benchmark rump-hvt dummy dmmy rump-hvt/dummy redis
# run-benchmark vm nokml notiny ./kernelbuild/microvm/vmlinux redis
# run-benchmark vm kml notiny ./kernelbuild/lupine-djw-kml++redis/vmlinux redis
# run-benchmark vm kml tiny ./kernelbuild/lupine-djw-kml-tiny++redis/vmlinux redis
# run-benchmark vm nokml notiny ./kernelbuild/lupine-djw-nokml++redis/vmlinux redis
# run-benchmark vm nokml tiny ./kernelbuild/lupine-djw-nokml-tiny++redis/vmlinux redis

run-benchmark osv dummy dummy redis

# run-benchmark hermitux dummy dummy redis

for f in benchmark-logs/*.log; do
    if [[ $f == *"redis"* ]]; then
        printf "Redis-Get "
        printf "$(basename $f | sed 's/.log//' | cut -d'.' -f2) "
        grep GET $f | cut -d',' -f2 | tr -d '"' | sort -R | tail -n30 | st | tail -n1
        printf "Redis-Set "
        printf "$(basename $f | sed 's/.log//' | cut -d'.' -f2) "
        grep SET $f | cut -d',' -f2 | tr -d '"' | sort -R | tail -n30 | st | tail -n1
    fi
    if [[ $f == *"nginxconn"* ]]; then
        printf "Nginx-conn "
        printf "$(basename $f | sed 's/.log//' | cut -d'.' -f2) "
        grep Req $f | awk '{print $4}' | sort -R | tail -n30 | st | tail -n1
    elif [[ $f == *"nginxsess"* ]]; then
        printf "Nginx-sess "
        printf "$(basename $f | sed 's/.log//' | cut -d'.' -f2) "
        grep Req $f | awk '{print $4}' | sort -R | tail -n30 | st | tail -n1
    fi
done
