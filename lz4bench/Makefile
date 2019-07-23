
lz4.ext2:
	dd if=/dev/zero of=$@ bs=1 count=0 seek=32M
	mkfs.ext2 $@
	mkdir -p mnt
	sudo mount $@ mnt
	sudo cp fullbench mnt/.
	sudo cp alice29 mnt/.
	sudo umount mnt
	rmdir mnt
