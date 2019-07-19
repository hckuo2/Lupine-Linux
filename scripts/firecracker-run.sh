#!/bin/bash -e
source scripts/run-helper.sh

SOCKET=/tmp/firecracker.socket
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
KERNEL=`readlink -e $1`
ROOTFS=`readlink -e $2`
INIT=$3

    curl --unix-socket $SOCKET -i  \
        -X PATCH 'http://localhost/machine-config' \
        -H 'Accept: application/json'            \
        -H 'Content-Type: application/json'      \
        -d '{
            "mem_size_mib": 2024
        }'
    curl --silent --unix-socket $SOCKET -i \
        -X PUT 'http://localhost/boot-source'   \
        -H 'Accept: application/json'           \
        -H 'Content-Type: application/json'     \
        -d '{
            "kernel_image_path": "'$KERNEL'",
            "boot_args": "console=ttyS0 reboot=k panic=1 pci=off init=/'"$INIT"'"
        }'

    curl --silent --unix-socket $SOCKET -i \
        -X PUT 'http://localhost/drives/rootfs' \
        -H 'Accept: application/json'           \
        -H 'Content-Type: application/json'     \
        -d '{
            "drive_id": "rootfs",
            "path_on_host": "'$ROOTFS'",
            "is_root_device": true,
            "is_read_only": false
        }'

    curl --silent --unix-socket $SOCKET -i \
        -X PUT 'http://localhost/network-interfaces/eth0' \
        -H 'Accept: application/json'           \
        -H 'Content-Type: application/json'     \
        -d '{
            "iface_id": "eth0",
            "guest_mac": "AA:FC:00:00:00:01",
            "host_dev_name": "tap'$TAP'"
        }'


    curl --silent --unix-socket $SOCKET -i \
        -X PUT 'http://localhost/actions'       \
        -H  'Accept: application/json'          \
        -H  'Content-Type: application/json'    \
        -d '{
            "action_type": "InstanceStart"
        }'
