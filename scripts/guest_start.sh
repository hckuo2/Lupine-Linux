#!/bin/sh
export PATH="/usr/local/bin:$PATH"
sh guest_net.sh
mkdir -p /trusted

echo "APP START"

if which mysql; then
    echo ========NOKML=========
    MYSQL_ALLOW_EMPTY_PASSWORD=yes /entrypoint.sh mysqld
fi
if which mongo; then
    echo ========NOKML=========
    /usr/local/bin/docker-entrypoint.sh mongod   
fi
if which nginx; then
    cp `which nginx` /trusted
    if echo $@ | grep trusted - > /dev/null; then
        echo ========KML=========
        /trusted/libc.so /trusted/nginx -g 'daemon off;'
    else
        echo ========NOKML=========
        $@ -g 'daemon off;'
    fi
fi
if which redis-server; then
    cp `which redis-server` /trusted
    if echo $@ | grep trusted - > /dev/null; then
        echo ========KML=========
        /trusted/libc.so $@;
    else
        echo ========NOKML=========
        $@
    fi
fi
