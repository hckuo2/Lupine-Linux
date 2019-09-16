#!/bin/bash
measure_mem() {
    SYS=$1
    KERNEL=$2
    shift
    shift
    RESULT="measure-mm-result"
    KERNEL_OPTS="panic=-1 pci=off reboot=k tsc=reliable quiet "
    KERNEL_OPTS+="8250.nr_uarts=1 ipv6.disable=1 init=/hello"

    left=0
    right=1024
    while [[ $left -le $right ]]; do

        mem=$(((left+right)/ 2))

        if [ x"$SYS" == "xvm" ]; then
            [ -f hello-world.ext2 ] || ./scripts/image2rootfs.sh hello-world \
                latest ext2
            # if we do not see the desired output from the guest after this
            # timeout we consider the guest does not work.
            ( sleep 10 && pkill -9 firecracker && pkill -9 firectl) &
            cleanup_pid=$!
            firectl --firecracker-binary=$(pwd)/firecracker \
                --kernel $KERNEL \
                --root-drive=hello-world.ext2  \
                --kernel-opts="$KERNEL_OPTS" \
                --ncpus=1 \
                --memory=$mem > $RESULT #2> /dev/null

        elif [ x"$SYS" == "xhermitux" ]; then
            docker run -v ~/hermitux:/hermitux --rm --privileged -it \
                -e HERMIT_ISLE=uhyve -e HERMIT_TUX=1 -e HERMIT_MEM="$mem"M \
                olivierpierre/hermitux \
                /root/hermitux/hermitux-kernel/prefix/bin/proxy \
                /root/hermitux/hermitux-kernel/prefix/x86_64-hermit/extra/tests/hermitux hello
        fi

        if grep -q "hello" $RESULT; then
            right=$(($mem - 1))
        else
            left=$(($mem + 1))
        fi

        kill -9 $cleanup_pid &> /dev/null

    done
    echo $mem
}

measure_mem vm kernelbuild/lupine-djw-kml/vmlinux
