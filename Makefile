
qemu-test:
	qemu-system-x86_64 -enable-kvm -no-reboot -kernel linux/arch/x86_64/boot/bzImage -drive "file=./lat_syscall.ext2,format=raw" -nographic -nodefaults -serial stdio -append "panic=-1 console=ttyS0 root=/dev/sda rw loglevel=15 nokaslr init=/bin/ash"

build-env-image:
	cd docker && \
		docker build . -t linuxbuild:latest -f build-env.Dockerfile


patch-linux:
	cd linux && \
		git apply ../kml_4.0_001.diff

build-linux:
	docker run -it -v "$(PWD)/linux":/linux-volume --rm linuxbuild:latest	\
		bash -c "make -j8 -C /linux-volume"

build-linux-lto:
	docker run -it -v "$(PWD)/linux-misc":/linux-volume --rm linuxbuild:latest	\
		bash -c "make -j8 -C /linux-volume"

run-hello:
	make -C hello
	qemu-system-x86_64 \
	-kernel linux/arch/x86_64/boot/bzImage \
	-initrd hello/initramfs-hello.cpio.gz \
	-nographic -enable-kvm \
	-append "init=/trusted/hello console=ttyS0"

debuggable:
	cd linux; \
	./scripts/config --enable DEBUG_KERNEL; \
	./scripts/config --enable DEBUG_INFO; \
	./scripts/config --disable DEBUG_INFO_REDUCED; \
	./scripts/config --enable DEBUG_INFO_SPLIT; \
	./scripts/config --enable DEBUG_INFO_DWARF4; \
	./scripts/config --enable GDB_SCRIPTS

ext4-fs:
	cd linux; \
	./scripts/config --enable EXT4_FS; \
	./scripts/config --enable BLOCK;

ide-drive:
	cd linux; \
	./scripts/config --enable BLOCK; \
	./scripts/config --enable BLK_DEV_SD; \
	./scripts/config --enable ATA_PIIX; \
	./scripts/config --enable ATA; \
	./scripts/config --enable SATA_AHCI; \
	./scripts/config --enable SCSI_CONSTANTS; \
	./scripts/config --enable SCSI_SPI_ATTRS; \

serial:
	cd linux; \
	./scripts/config --enable SERIAL_8250; \
	./scripts/config --enable SERIAL_8250_CONSOLE; \

printk:
	cd linux; \
	./scripts/config --enable EXPERT; \
	./scripts/config --enable PRINTK;

tty:
	cd linux; \
	./scripts/config --enable EXPERT; \
	./scripts/config --enable TTY;

exe:
	cd linux; \
	./scripts/config --enable BINFMT_ELF; \
	./scripts/config --enable BINFMT_SCRIPT;

64bit:
	cd linux; \
	./scripts/config --enable 64BIT;

network:
	cd linux; \
	./scripts/config --enable NET; \
	./scripts/config --enable INET;

futex:
	cd linux; \
	./scripts/config --enable EXPERT; \
	./scripts/config --enable FUTEX;

epoll:
	cd linux; \
	./scripts/config --enable EXPERT; \
	./scripts/config --enable EPOLL; \
	./scripts/config --enable SIGNALFD;

audit:
	cd linux; \
	./scripts/config --enable AUDIT; \
	./scripts/config --enable AUDITSYSCALL; \
	./scripts/config --eanble AUDIT_WATCH; \
	./scripts/config --enable AUDIT_TREE; \
	./scripts/config --enable INTEGRITY_AUDIT;

proc:
	cd linux; \
	./scripts/config --enable PROC_FS;

smp:
	cd linux; \
	./scripts/config --enable SMP; \
	./scripts/config --enable X86_64_SMP;

unix-socket:
	cd linux; \
	./scripts/config --enable UNIX;

multiuser:
	cd linux; \
	./scripts/config --enable MULTIUSER;

ftrace:
	cd linux; \
	./scripts/config --enable DEBUG_FS; \
	./scripts/config --enable FTRACE; \
	./scripts/config --enable FUNCTION_TRACER; \
	./scripts/config --enable FUNCTION_GRAPH_TRACER; \
	./scripts/config --enable FUNCTION_STACK_TRACER; \
	./scripts/config --enable FUNCTION_DYNAMIC_TRACER;

