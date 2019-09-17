#!/bin/bash
VMMSOCKET=~/.firecracker.socket
RESULT="measure-mm-result"
KERNEL_OPTS="panic=-1 noapic nomodules pci=off "
KERNEL_OPTS+="console=ttyS0  "
TIMEOUT=5

cleanup-fc() {
    pkill -9 firecracker
    rm $VMMSOCKET
}

measure_mem() {
    SYS=$1
    KERNEL=$2
    DISK=$3
    echo $SYS $KERNEL $DISK
    shift
    shift
    shift
    BIN=$@
    KERNEL_OPTS+="init="$BIN

    left=0
    right=64
    while [[ $left -lt $right ]]; do

        rm $RESULT
        mem=$(((left+right)/ 2))
        echo $mem

        if [ x"$SYS" == "xvm" ]; then
            [ -f hello-world.ext2 ] || ./scripts/image2rootfs.sh hello-world \
                latest ext2
            # if we do not see the desired output from the guest after this
            # timeout we consider the guest does not work.
            ( sleep $TIMEOUT; cleanup-fc ) &
            sleep_pid=$(pgrep -P $!)
            sleep 4
            firectl --firecracker-binary=$(pwd)/firecracker \
                --kernel $KERNEL \
                --root-drive=$DISK \
                --kernel-opts="$KERNEL_OPTS" \
                --ncpus=1 \
                --socket-path=$VMMSOCKET \
                --memory=$mem > $RESULT #2> /dev/null

        elif [ x"$SYS" == "xhermitux" ]; then
            ( sleep $TIMEOUT; sudo pkill -f -9 hermitux-kernel) &
            sleep_pid=$(pgrep -P $!)
            docker run -v ~/hermitux:/hermitux --rm --privileged -it \
                -e HERMIT_ISLE=uhyve -e HERMIT_TUX=1 -e HERMIT_MEM="$mem"M \
                olivierpierre/hermitux \
                /root/hermitux/hermitux-kernel/prefix/bin/proxy \
                /root/hermitux/hermitux-kernel/prefix/x86_64-hermit/extra/tests/hermitux \
                            /hermitux/hello > $RESULT
        fi
        if [[ "$BIN" == *"hello"* ]]; then
            CONDITION='grep -q "hello" $RESULT'
        elif [[ "$BIN" == *"redis"* ]]; then
            CONDITION='grep -q "Ready to accept connections" $RESULT'
        fi

        if eval $CONDITION; then
            right=$(($mem - 1))
        else
            left=$(($mem + 1))
        fi

        kill -9 $sleep_pid &> /dev/null

    done
    echo $SYS "$BIN" $mem
}

measure_mem vm kernelbuild/lupine-djw-kml/vmlinux hello-world.ext2 /hello
measure_mem vm kernelbuild/lupine-djw-kml++redis/vmlinux redis.ext2 \
    /usr/local/bin/redis-server
# measure_mem vm kernelbuild/microvm/vmlinux /hello | tail -n1 2>/dev/null
# measure_mem hermitux dummy /hermitux/hello | tail -n1 | tail -n1
