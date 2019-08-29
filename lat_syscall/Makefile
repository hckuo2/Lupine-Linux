all: lat_syscall lat_syscall-static

MUSL_DIR=/home/djwillia/musl
MUSL_INSTALL_DIR=/home/djwillia/musl/stuff/musl
MUSL_GCC=$(MUSL_INSTALL_DIR)/bin/musl-gcc

.PHONY: always
libc.so: always
	make -C $(MUSL_DIR) install \
	&& cp $(MUSL_INSTALL_DIR)/lib/libc.so .

lat_syscall-static: libc.so lat_syscall.c Makefile
	$(MUSL_GCC) -g -o $@ -static lat_syscall.c lib_timing.c

lat_syscall: libc.so lat_syscall.c Makefile
	$(MUSL_GCC) -o $@ lat_syscall.c lib_timing.c

docker: Dockerfile lat_syscall lat_syscall-static
	docker build -t lat_syscall .

image: docker
	(cd .. && scripts/image2rootfs.sh lat_syscall latest ext2)

clean:
	rm -f lat_syscall lat_syscall-static
