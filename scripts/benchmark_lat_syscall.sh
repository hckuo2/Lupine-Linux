#!/bin/bash -e
source scripts/run-helper.sh
rep=1000000
itr=20
types="null read write"
osv=~/osv

run_test() {
    SYS=$1
    KERNEL=$2
    shift
    shift
    BIN=$@
    for t in $types; do 
        echo -n "$KERNEL ${BIN/ /,} $t $itr $rep "
        for i in `seq $itr`; do
            if [ "x$SYS" == "xvm" ]; then
                firectl --firecracker-binary=$(pwd)/firecracker \
                        --kernel $KERNEL \
                        --tap-device=tap100/AA:FC:00:00:00:01 \
                        --root-drive=lat_syscall.ext2 \
                        --kernel-opts="console=ttyS0 noapic  panic=-1 pci=off nomodules rw init=$BIN -N $rep $t"
            elif [ "x$SYS" == "xosv" ]; then
                sudo $osv/scripts/firecracker.py -e "/lat_syscall -N $rep $t"
            elif [ "x$SYS" == "xhermitux" ]; then
                docker run -v ~/hermitux:/hermitux --rm --privileged -it olivierpierre/hermitux bash -c "/hermitux/apps/lmbench3/lat_syscall/run-test2.sh $rep $t"
            elif [ "x$SYS" == "xhost" ]; then
                docker run --rm -it lat_syscall $BIN -N $rep $t
            fi
        done 2>&1 | grep "res:" | cut -d: -f2 | stat
    done
}

run_test host host /libc.so /lat_syscall
run_test hermitux hermitux /lat_syscall
run_test osv osv /lat_syscall
run_test vm $(pwd)/kernelbuild/microvm/vmlinux /libc.so /lat_syscall
run_test vm $(pwd)/kernelbuild/lupine-djw-kml/vmlinux /libc.so /lat_syscall
run_test vm $(pwd)/kernelbuild/lupine-djw-kml/vmlinux /trusted/libc.so /trusted/lat_syscall



#run_test vm $(pwd)/kernelbuild/microvm-paravirt+kml/vmlinux /lat_syscall
#run_test vm $(pwd)/kernelbuild/lupine+kml+mmio+O2/vmlinux /lat_syscall
# run_test vm $(pwd)/kernelbuild/lupine+kml+mmio/vmlinux /trusted/lat_syscall
