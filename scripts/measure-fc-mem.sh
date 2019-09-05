#!/bin/bash
KERNEL=$1
if ! [[ -f $KERNEL ]]; then
    echo $KERNEL does not exist
    exit 1
fi
VMM_STDOUT=vmmstdout
VMM_STDERR=vmmstderr
VMM_SOCKET=vmmsocket
cleanup() {
    pkill -9 firecracker
    pkill -9 firectl
    rm -f $VMM_STDOUT $VMM_STDERR $VMM_SOCKET
}
KERNEL_OPTS="panic=-1 pci=off reboot=k tsc=reliable quiet 8250.nr_uarts=1 "
KERNEL_OPTS+="ipv6.disable=1 init=/hello"
[ -f hello-world.ext2 ] || ./scripts/image2rootfs.sh hello-world latest ext2
# Binary search
left=0
right=1024
while [[ $left -le $right ]]; do
    cleanup
    mem=$(((left+right)/ 2))
    echo $left $mem $right
    # if we do not see the desired output from the guest after this timeout we
    # consider the guest does not work.
    ( sleep 5 && cleanup ) &
    cleanup_pid=$!
    firectl --firecracker-binary=$(pwd)/firecracker \
        --kernel $KERNEL \
        --socket-path=$VMM_SOCKET \
        --root-drive=hello-world.ext2  \
        --kernel-opts="$KERNEL_OPTS" \
        --ncpus=1 \
        --memory=$mem 2> $VMM_STDERR > $VMM_STDOUT

    if grep -q "firecracker exited: status=0" $VMM_STDERR; then
        kill -9 $cleanup_pid &> /dev/null
        right=$(($mem - 1))
    else
        left=$(($mem + 1))
    fi
done
echo $mem
