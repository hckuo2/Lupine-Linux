# this file is uesd to build the Docker image for benchmarking KML
# with different crossing (kernel<->user) rates
FROM alpine 
RUN mkdir -p /trusted
ADD libc.so /trusted/
ADD crossing /trusted
ADD crossing /
CMD ["/crossing"]
