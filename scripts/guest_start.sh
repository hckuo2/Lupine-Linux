#!/bin/sh
export PATH="/usr/local/bin:$PATH"
sh guest_net.sh
mkdir -p /trusted
if which nginx; then
    echo "daemon off;" >> /etc/nginx/nginx.conf
    cp `which nginx` /trusted
fi
if which redis-server; then
    cp `which redis-server` /trusted
fi
ls -l /usr/local/bin
ls -l /trusted
$@
