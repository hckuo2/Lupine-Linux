#!/bin/sh
export PATH="/usr/local/bin:$PATH"
mkdir -p /trusted

echo "APP START"

if which php; then
    echo ========NOKML=========
    ./guest_load_entropy 1000
    /usr/local/bin/php -r 'echo "hello\n";'
fi

if which mysql; then
    sh guest_net.sh
    echo ========NOKML=========
    MYSQL_ALLOW_EMPTY_PASSWORD=yes /entrypoint.sh mysqld
fi

if which postgres; then
    sh guest_net.sh
    echo ========NOKML=========
    export POSTGRES_PASSWORD=mysecretpassword
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    export LANG=en_US.utf8
    export PG_MAJOR=11
    export PG_VERSION=11.5
    export PG_SHA256=7fdf23060bfc715144cbf2696cf05b0fa284ad3eb21f0c378591c6bca99ad180
    export PGDATA=/var/lib/postgresql/data
    ./guest_load_entropy 1000

    echo "mysecretpassword" > /pw
    sed -i s/"--pwfile=<(echo \"\\\$POSTGRES_PASSWORD\")"/"--pwfile=\/pw"/ docker-entrypoint.sh
    /docker-entrypoint.sh postgres &
fi

if which mongo; then
    sh guest_net.sh
    echo ========NOKML=========
    /usr/local/bin/docker-entrypoint.sh mongod   
fi

if which nginx; then
    sh guest_net.sh
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
    sh guest_net.sh
    cp `which redis-server` /trusted
    if echo $@ | grep trusted - > /dev/null; then
        echo ========KML=========
        /trusted/libc.so $@;
    else
        echo ========NOKML=========
        $@
    fi
fi
