#!/bin/bash
source scripts/run-helper.sh
VMMSOCKET=~/.firecracker.socket
RESULT="$DIR/measure-mm-result"
TIMEOUT=3

cleanup-fc() {
    sudo pkill -9 firecracker
    sudo pkill -9 firectl
    sudo rm -f $VMMSOCKET
}

measure_mem() {
    SYS=$1
    KERNEL=$2
    DISK=$3
    shift
    shift
    shift
    BIN=$@
    KERNEL_OPTS="panic=-1 noapic nomodules pci=off "
    KERNEL_OPTS+="console=ttyS0  "
    KERNEL_OPTS+="init="$BIN

    if [ x"$SYS" == "xosv" ]; then
        pushd osv
        ./scripts/build image=$BIN fs=zfs
        popd
    fi

    for i in $(seq 3); do
        left=0
        right=64
        result=$right
        while [[ $left -le $right ]]; do
            sudo rm -f $RESULT
            mem=$(((left+right)/ 2))
            echo $mem

            if [ x"$SYS" == "xvm" ]; then
                # if we do not see the desired output from the guest after this
                # timeout we consider the guest does not work.
                {
                    sleep $TIMEOUT
                    cleanup-fc
                } &
                sleep_pid=$(pgrep -P $!)
                firectl --firecracker-binary=$(pwd)/firecracker \
                    --kernel $KERNEL \
                    --root-drive=$DISK \
                    --kernel-opts="$KERNEL_OPTS" \
                    --ncpus=1 \
                    --socket-path=$VMMSOCKET \
                    --memory=$mem > $RESULT 2> /dev/null

            elif [ x"$SYS" == "xhermitux" ]; then
                TIMEOUT=5
                ( sleep $TIMEOUT; sudo pkill -f -9 hermitux-kernel) &
                sleep_pid=$(pgrep -P $!)
                docker run -v ~/hermitux:/hermitux --rm --privileged -it \
                    -e HERMIT_ISLE=uhyve -e HERMIT_TUX=1 -e HERMIT_MEM="$mem"M \
                    olivierpierre/hermitux \
                    /root/hermitux/hermitux-kernel/prefix/bin/proxy \
                    /root/hermitux/hermitux-kernel/prefix/x86_64-hermit/extra/tests/hermitux \
                    $BIN > $RESULT

                reset -w
            elif [ x"$SYS" == "xosv" ]; then
                pushd osv
                {
                    sleep $TIMEOUT
                    cleanup-fc
                } &
                sudo FIRECRACKER_PATH=../firecracker ./scripts/firecracker.py \
                    -c 1 -m "$mem"M > $RESULT
                popd
            fi
            if [[ "$BIN" == *"native-example"* ]]; then
                CONDITION='grep -q "hello" $RESULT'
            elif [[ "$BIN" == *"hello"* ]]; then
                CONDITION='grep -q "hello" $RESULT'
            elif [[ "$BIN" == *"redis"* ]]; then
                CONDITION='grep -iq "Ready to accept connections" $RESULT'
            elif [[ "$BIN" == *"nginx"* ]]; then
                CONDITION='grep -iq "nginx" $RESULT'
            fi

            if eval $CONDITION; then
                right=$(($mem - 1))
                result=$mem
            else
                left=$(($mem + 1))
            fi

            wait
        done
        echo "Result:" $SYS $KERNEL "$BIN" $result
    done 2>/dev/null | grep Result: | sort -k5,5 -nr | tail -n1
}

## base (hello)
measure_mem vm kernelbuild/lupine-djw-kml++base/vmlinux hello-world.ext2 \
    /hello
measure_mem vm kernelbuild/lupine-djw-kml-tiny++base/vmlinux hello-world.ext2 \
    /hello
measure_mem vm kernelbuild/lupine-djw-nokml++base/vmlinux hello-world.ext2 \
    /hello
measure_mem vm kernelbuild/lupine-djw-nokml-tiny++base/vmlinux hello-world.ext2 \
    /hello

measure_mem vm kernelbuild/microvm/vmlinux hello-world.ext2 /hello
measure_mem hermitux dummy dummy /hermitux/hello
measure_mem osv dummy dummy native-example

## redis
measure_mem vm kernelbuild/lupine-djw-kml++redis/vmlinux redis.ext2 \
    /usr/local/bin/redis-server
measure_mem vm kernelbuild/lupine-djw-kml-tiny++redis/vmlinux redis.ext2 \
    /usr/local/bin/redis-server
measure_mem vm kernelbuild/lupine-djw-nokml++redis/vmlinux redis.ext2 \
    /usr/local/bin/redis-server
measure_mem vm kernelbuild/lupine-djw-nokml-tiny++redis/vmlinux redis.ext2 \
    /usr/local/bin/redis-server

measure_mem vm kernelbuild/microvm/vmlinux redis.ext2 \
    /usr/local/bin/redis-server
measure_mem hermitux dummy dummy /hermitux/redis-server
measure_mem osv dummy dummy redis-memonly

## nginx
measure_mem vm kernelbuild/lupine-djw-kml++nginx/vmlinux nginx.ext2 \
    /usr/sbin/nginx
measure_mem vm kernelbuild/lupine-djw-kml-tiny++nginx/vmlinux nginx.ext2 \
    /usr/sbin/nginx
measure_mem vm kernelbuild/lupine-djw-nokml++nginx/vmlinux nginx.ext2 \
    /usr/sbin/nginx
measure_mem vm kernelbuild/lupine-djw-nokml-tiny++nginx/vmlinux nginx.ext2 \
    /usr/sbin/nginx

measure_mem vm kernelbuild/microvm/vmlinux nginx.ext2 \
    /usr/sbin/nginx
measure_mem osv dummy dummy nginx
