#!/bin/bash -e
rm -f /tmp/firecracker.socket
./firecracker --api-sock /tmp/firecracker.socket
