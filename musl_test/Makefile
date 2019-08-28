all: hello hello-static

MUSL_DIR=/home/djwillia/musl
MUSL_INSTALL_DIR=/home/djwillia/musl/stuff/musl
MUSL_GCC=$(MUSL_INSTALL_DIR)/bin/musl-gcc

hello: libc.so hello.c
	$(MUSL_GCC) hello.c -o hello

hello-static: libc.so hello.c
	$(MUSL_GCC) -static hello.c -o hello-static

.PHONY: always
libc.so: always
	make -C $(MUSL_DIR) install \
	&& cp $(MUSL_INSTALL_DIR)/lib/libc.so .

docker: Dockerfile hello libc.so
	docker build -t musl_test .

image: docker
	(cd .. && scripts/image2rootfs.sh musl_test latest ext2)

clean:
	rm -f hello libc.so
