#!/bin/sh
export PATH="/usr/local/bin:$PATH"
sh guest_net.sh
mkdir -p /trusted
if which nginx; then
    cp `which nginx` /trusted
fi
if which redis-server; then
    cp `which redis-server` /trusted
fi
echo $1
if [ x"$1" == "x/trusted/"* ]; then
    echo "KML mode is really on!"
    /trusted/libc.so $@ -g 'daemon off;'
else
    echo "KML mode is really off!"
    $@ -g 'daemon off;'
fi
