
all: initramfs-hello.cpio.gz

initramfs-hello.cpio.gz: trusted/hello
	find . -print0 \
	| cpio --null -ov --format=newc \
	| gzip -9 > initramfs-hello.cpio.gz

trusted/hello: hello.c
	gcc -static hello.c -o trusted/hello

clean:
	rm -f hello initramfs-hello.cpio.gz
