#!/bin/bash
# Usage: ./image2rootfs.sh app tag
die() { echo "$*" 1>&2 ; exit 1; }

app=$1
tag=$2
fs=${3:-ext2}

container_id=$(docker create $app:$tag || die "run container failed.")
if [ "$container_id" == "" ]; then
    die "empty container id."
fi

docker export $container_id > $app.tar || die "failed to create tar."
docker rm $container_id;

mnt=$(mktemp -d)
dd if=/dev/zero of=$app.$fs bs=1 count=0 seek=10G
mkfs.$fs $app.$fs
sudo mount $app.$fs $mnt
sudo tar -xvf $app.tar -C $mnt
sudo umount $mnt
rmdir $mnt
