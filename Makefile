build-env-image:
	cd docker && \
		docker build . -t linuxbuild:latest -f build-env.Dockerfile


patch-linux:
	cd linux && \
		git apply ../kml_4.0_001.diff

build-linux:
	docker run -it -v "$(PWD)/linux":/linux-volume --rm linuxbuild:latest	\
		bash -c "make -C /linux-volume"

run-hello: 
	make -C hello
	qemu-system-x86_64 \
	-kernel linux/arch/x86_64/boot/bzImage \
	-initrd hello/initramfs-hello.cpio.gz \
	-nographic -enable-kvm \
	-append "init=/trusted/hello console=ttyS0"
