

KERNEL=kernelbuild/lupine-djw-nokml++mysql/vmlinux
FS=mysql.ext2

sudo killall firecracker
scripts/build-with-configs.sh nopatch configs/lupine-djw-nokml.config configs/mysql.config
yes y | scripts/image2rootfs.sh mysql latest ext2

sudo firectl --firecracker-binary=$(pwd)/firecracker --kernel $KERNEL --tap-device=tap100/AA:FC:00:00:00:01 --root-drive=$FS --kernel-opts="panic=-1 pci=off reboot=k tsc=reliable ipv6.disable=1 console=ttyS0 init=/guest_start.sh"
