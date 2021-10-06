all: lat_syscall lat_syscall-static

check_env:
ifndef MUSL_INSTALL_DIR
	$(error MUSL_INSTALL_DIR is not set. Please set in the shell and execute again)
endif
ifndef MUSL_GCC
	$(error MUSL_GCC is not set. Please set it in the shell and execute again)
endif

.PHONY: always
libc.so: check_env always
ifdef MUSL_DIR
	make -C $(MUSL_DIR) install
endif
	cp $(MUSL_INSTALL_DIR)/lib/libc.so .

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
