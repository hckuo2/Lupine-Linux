#!/bin/bash
VMMSOCKET=~/.firecracker.socket
RESULT="measure-mm-result"
KERNEL_OPTS="panic=-1 pci=off reboot=k tsc=reliable quiet "
KERNEL_OPTS+="console=ttyS0 8250.nr_uarts=1 ipv6.disable=1 init=/hello"

cleanup-fc() {
    pkill -9 firecracker
    rm $VMMSOCKET
}

measure_mem() {
    SYS=$1
    KERNEL=$2
    shift
    shift

    left=0
    right=1024
    while [[ $left -le $right ]]; do

        mem=$(((left+right)/ 2))
        echo $mem

        if [ x"$SYS" == "xvm" ]; then
            [ -f hello-world.ext2 ] || ./scripts/image2rootfs.sh hello-world \
                latest ext2
            # if we do not see the desired output from the guest after this
            # timeout we consider the guest does not work.
            ( sleep 10; cleanup-fc ) &
            sleep_pid=$(pgrep -P $!)
            sleep 1
            firectl --firecracker-binary=$(pwd)/firecracker \
                --kernel $KERNEL \
                --root-drive=hello-world.ext2  \
                --kernel-opts="$KERNEL_OPTS" \
                --ncpus=1 \
                --socket-path=$VMMSOCKET \
                --memory=$mem > $RESULT #2> /dev/null

        elif [ x"$SYS" == "xhermitux" ]; then
            ( sleep 10; sudo pkill -f -9 hermitux-kernel) &
            sleep_pid=$(pgrep -P $!)
            docker run -v ~/hermitux:/hermitux --rm --privileged -it \
                -e HERMIT_ISLE=uhyve -e HERMIT_TUX=1 -e HERMIT_MEM="$mem"M \
                olivierpierre/hermitux \
                /root/hermitux/hermitux-kernel/prefix/bin/proxy \
                /root/hermitux/hermitux-kernel/prefix/x86_64-hermit/extra/tests/hermitux \
                            /hermitux/hello > $RESULT
        fi

        if grep -q "hello" $RESULT; then
            right=$(($mem - 1))
        else
            left=$(($mem + 1))
        fi
        rm $RESULT

        kill -9 $sleep_pid &> /dev/null

    done
    echo Result: $mem
}

measure_mem vm kernelbuild/lupine-djw-kml/vmlinux | tail -n1 2>/dev/null
measure_mem vm kernelbuild/microvm/vmlinux | tail -n1 2>/dev/null
measure_mem hermitux dummy | tail -n1 | tail -n1
