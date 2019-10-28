#!/bin/sh
rep=1000000
itr=10
types="null read write"

mean() {
    awk '{sum+=$1}END{print sum/NR}'
}

stat() {
    awk '{x+=$0;y+=$0^2}END{print x/NR, sqrt(y/NR-(x/NR)^2)}'
}

for t in $types; do 
    printf "%s " $t
    for i in `seq $itr`; do
	./solo5-spt lat_syscall.spt  '{"cmdline":"lat -N '$rep' '$t'"}'
    done | grep "res:" | cut -d: -f2 | stat
done
