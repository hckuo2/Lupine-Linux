#!/bin/sh

sleep_forever() {
    sleep 999999999
}

for i in $(seq $1); do
    sleep_forever &
done

for i in $(seq $2); do
    echo "null:" $(/trusted/libc.so /trusted/lat_syscall -N 1000000 null)
    echo "read:" $(/trusted/libc.so /trusted/lat_syscall -N 1000000 read)
    echo "write:" $(/trusted/libc.so /trusted/lat_syscall -N 1000000 write)
done

