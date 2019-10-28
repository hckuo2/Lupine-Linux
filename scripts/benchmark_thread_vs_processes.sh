#!/bin/bash
source scripts/run-helper.sh
kernel=kernelbuild/lupine-djw-nokml++nginx/vmlinux

if [ ! -f perf.ext2 ]; then
    ./scripts/image2rootfs.sh perf latest ext2
fi

benchmark_messaging() {
    kernel=$2
    for num_groups in 1 2 4 8 16; do
        printf "%s %s %d " $1 $kernel $num_groups
        for i in `seq 30`; do
            kernel_opts="console=ttyS0 noapic \
                panic=-1 pci=off nomodules init=/trusted/libc.so /usr/bin/perf \
                bench sched messaging -g $num_groups "
            if [[ $1 == "threaded" ]]; then
                kernel_opts=$kernel_opts:"-t"
            fi
            taskset -c $SERVER_CPUS firectl --firecracker-binary=$(pwd)/firecracker \
                --kernel $kernel \
                --ncpus=1 --memory=512 \
                --root-drive=perf.ext2 \
                --kernel-opts="$kernel_opts"
        done 2>/dev/null | grep "Total time" | awk '{print $3}' | sort -R \
         | tail -n30 | st | tail -n1
    done
}

benchmark_messaging process kernelbuild/lupine-djw-nokml++nginx/vmlinux
benchmark_messaging threaded kernelbuild/lupine-djw-nokml++nginx/vmlinux
benchmark_messaging process kernelbuild/lupine-djw-kml++nginx/vmlinux
benchmark_messaging threaded kernelbuild/lupine-djw-kml++nginx/vmlinux

