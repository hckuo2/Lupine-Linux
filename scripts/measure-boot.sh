#!/bin/bash

KERNEL=$1
total=0
FCDIR=$(pwd)

encode-kernel-name() {
    basename $(dirname $1) | sed 's/-djw//' \
        | sed 's/++base//'
}

measure-boot() {
    TYPE=$1
    KERNEL=$2
    LOG=bootlog
    if [[ $TYPE == "vm" ]]; then
        [ -f measure-boot.ext2 ] || ./scripts/image2rootfs.sh measure-boot \
            latest ext2 > /dev/null 2>&1
        [ -e $KERNEL ] || {
            echo $KERNEL not found
                exit 1
        }
        printf "$(encode-kernel-name $KERNEL) "
        for i in $(seq 50); do
            {
                sleep 0.5 && pkill firecracker;
            } &
            timeout=$!
            taskset -c $(seq -s',' 1 2 `nproc`) firectl \
                --firecracker-binary=$FCDIR/firecracker \
                --kernel=$KERNEL \
                --root-drive=measure-boot.ext2  \
                --firecracker-log=$LOG \
                --kernel-opts="ro panic=-1 pci=off reboot=k tsc=reliable quiet 8250.nr_uarts=0 ipv6.disable=1 init=/measure-boot-fc" > /dev/null 2>&1

            kill $timeout > /dev/null 2>&1
            grep boot-time $LOG
            rm $LOG
        done | grep boot-time | awk '{print $12}' | sort -n -r | tail -n30 | st | tail -n1
    elif [[ $TYPE == "hermitux" ]]; then
        printf "Hermitux "
        #docker run -v ~/hermitux:/hermitux --rm --privileged -it \
        #    olivierpierre/hermitux bash /hermitux/measureboot.sh 50 \
        #    | grep real | awk '{print $2}' | sed 's/[^0-9]//g' | sort -n -r \
        #    | tail -n30 | st | tail -n1
	sudo docker run --privileged -it kollerr/hermitux hyperfine "HERMIT_VERBOSE=0 HERMIT_ISLE=uhyve HERMIT_TUX=1 HERMIT_DEBUG=0 HERMIT_PROFILE=0 HERMIT_MINIFS=0 HERMIT_MEM=2G HERMIT_MINIFS_HOSTLOAD=.minifs HERMIT_NETIF= HERMIT_IP= HERMIT_GATEWAY= /root/hermitux/hermitux-kernel/prefix/bin/proxy /root/hermitux/hermitux-kernel/prefix/x86_64-hermit/extra/tests/hermitux /root/hermitux/apps/test-clock-gettime/prog"
    elif [[ $TYPE == "osv" ]]; then
        pushd osv
        printf "OSV-rofs "
        mkfifo scripts/metrics.fifo
        mkfifo scripts/log.fifo
        ./scripts/build image=native-example fs=rofs > /dev/null 2>&1
        for i in $(seq 50); do
            sudo FIRECRACKER_PATH=$FCDIR/firecracker ./scripts/firecracker.py -c 1 -m 512M
        done | grep Booted | awk '{print $4}' | tail -n30 | sort -nr | st | tail -n1

        printf "OSV-zfs "
        ./scripts/build image=native-example fs=zfs > /dev/null 2>&1
        for i in $(seq 50); do
            sudo FIRECRACKER_PATH=$FCDIR/firecracker ./scripts/firecracker.py -c 1 -m 512M
        done | grep Booted | awk '{print $4}' | tail -n30 | sort -nr | st | tail -n1
        printf "OSV-ramfs "
        ./scripts/build image=native-example fs=ramfs > /dev/null 2>&1
        for i in $(seq 50); do
            sudo FIRECRACKER_PATH=$FCDIR/firecracker ./scripts/firecracker.py -c 1 -m 512M
        done | grep Booted | awk '{print $4}' | tail -n30 | sort -nr | st | tail -n1
        popd
    fi
}

#measure-boot vm ./kernelbuild/microvm/vmlinux
#measure-boot vm ./kernelbuild/lupine-djw-kml/vmlinux
#measure-boot vm ./kernelbuild/lupine-djw-kml-tiny/vmlinux
#measure-boot vm ./kernelbuild/lupine-djw-nokml/vmlinux
#measure-boot vm ./kernelbuild/lupine-djw-nokml-tiny/vmlinux
for f in kernelbuild/lupine-djw-nokml*; do 
    measure-boot vm ./$f/vmlinux
done
# measure-boot hermitux dummy
# measure-boot osv dummy
