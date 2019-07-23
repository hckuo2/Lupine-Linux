firectl --firecracker-binary=$(pwd)/firecracker \
--kernel kernelbuild/lupine+kml+mmio/vmlinux \
--root-drive=lz4bench/lz4.ext2 \
--vmm-log-fifo=firelog \
-d \
--kernel-opts="console=ttyS0 panic=1 init=/fullbench alice29"
