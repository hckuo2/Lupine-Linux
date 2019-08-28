FROM alpine

ADD ./hello /hello
ADD ./hello /trusted/hello
ADD ./libc.so /libc.so
ADD ./libc.so /trusted/libc.so

ENTRYPOINT [ "/bin/ash" ]