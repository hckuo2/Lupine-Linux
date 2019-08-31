#!/bin/bash

KERNEL=$1
VMM_STDOUT=vmmstdout
VMM_STDERR=vmmstderr
total=0
KERNEL_OPTS="panic=-1 pci=off reboot=k tsc=reliable quiet 8250.nr_uarts=1 "
KERNEL_OPTS+="ipv6.disable=1 init=/hello"
[ -f hello-world.ext2 ] || ./scripts/image2rootfs.sh hello-world latest ext2

left=0
right=1024
mem=$right
while [ $left -le $right ]; do
    mem=$(((left+right)/ 2))
    echo $left $mem $right
    firectl --firecracker-binary=$(pwd)/firecracker \
        --kernel $KERNEL \
        --root-drive=hello-world.ext2  \
        --kernel-opts="$KERNEL_OPTS" \
        --memory=$mem 2> $VMM_STDERR > $VMM_STDOUT &

    # if we do not see the desired output from the guest after this timeout we
    # consider it not working.
    sleep 5
    pkill firecracker
    if grep -q "Hello from Docker" $VMM_STDOUT; then
        right=$(($mem - 1))
    else
        left=$(($mem + 1))
    fi
    rm $VMM_STDOUT $VMM_STDERR
done
echo $mem
