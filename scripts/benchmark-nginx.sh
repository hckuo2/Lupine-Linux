#!/bin/bash
source scripts/run-helper.sh
rates=$(seq 1000 100 2000)

echo 1 | sudo tee /proc/sys/net/ipv4/tcp_tw_reuse


encode-kernel-name() {
    basename $(dirname $1) | sed 's/-djw//' \
        | sed 's/++redis//' \
        | sed 's/++nginx//'
}

ITER=1

start_client() {
    host=$1
    rate=$2
    sleep 5

    taskset -c $CLIENT_CPUS httperf \
        --timeout 5 \
        --server $host --uri /index.html \
        --num-conn $((rate * 60)) \
        --rate $rate
        # taskset -c $CLIENT_CPUS httperf \
            # --wsess=$s,1000,0 \
            # --hog \
            # --server $host --uri /index.html
    sudo pkill firecracker
    sudo pkill httperf
}

run()
{
    TYPE=$1
    KML=$2
    KERNEL=$3
    APP=nginx
    LOG=benchmark-logs/nginx-OL.$(encode-kernel-name $KERNEL).log
    rm -f $LOG
    for i in `seq $ITER`; do
        if [[ $TYPE == "vm" ]]; then
            for r in ${rates[@]}; do
                delete_current_tap
                create_current_tap
                sleep 6
                start_client 192.168.100.2 $r >> $LOG 2>&1 &
                [ -f $APP.ext2 ] ||  ./scripts/image2rootfs.sh $APP alpine ext2
                cp $APP.ext2 $APP.ext2.disposible

                if [[ $KML == "kml" ]]; then
                    BIN=/trusted/nginx
                else
                    BIN=/usr/sbin/nginx
                fi

                taskset -c "$SERVER_CPUS" firectl --firecracker-binary=$(pwd)/firecracker \
                    --kernel $KERNEL \
                    --tap-device=tap100/AA:FC:00:00:00:01 \
                    --root-drive=$APP.ext2.disposible \
                    --ncpus=1 --memory=512 \
                    --kernel-opts="console=ttyS0 panic=-1 pci=off tsc=reliable ipv6.disable=1 init=/guest_start.sh $BIN"
            done

        elif [[ $TYPE == "osv" ]]; then
            for r in ${rates[@]}; do
                start_client 172.16.0.2 $r >> $LOG 2>&1 &
                pushd osv
                taskset -c $SERVER_CPUS sudo FIRECRACKER_PATH=../firecracker \
                    ./scripts/firecracker.py -c 1 -m 512M -n
                popd
            done
        fi
    done
}

run vm kml ./kernelbuild/lupine-djw-kml++nginx/vmlinux
run vm kml ./kernelbuild/lupine-djw-kml-tiny++nginx/vmlinux
run vm nokml ./kernelbuild/lupine-djw-nokml++nginx/vmlinux
run vm nokml ./kernelbuild/lupine-djw-nokml-tiny++nginx/vmlinux
run osv dummy osv/dummy
