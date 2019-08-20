all: trusted/lat_syscall

trusted/lat_syscall: lat_syscall.c
	mkdir -p trusted
	gcc -o $@ -static lat_syscall.c lib_timing.c

docker: Dockerfile trusted/lat_syscall
	docker build -t lat_syscall .

clean:
	rm -f trusted/lat_syscall
	rmdir trusted
