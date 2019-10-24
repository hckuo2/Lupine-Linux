#!/bin/sh
export PATH="/usr/local/bin:$PATH"
mkdir -p /trusted
mount -t proc proc /proc
ulimit -n 65535

echo "APP START"

if [ -f /usr/bin/stress-ng ]; then
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    cd /usr/src/linux-stable
    #hyperfine --prepare 'make clean' --parameter-scan num_threads 1 12 'make -j {num_threads}'
    #hyperfine --prepare 'make clean' --parameter-scan num_threads 20 100 -D 10 'make -j {num_threads}'
    #hyperfine --prepare 'make clean' --parameter-scan num_threads 200 1000 -D 100 'make -j {num_threads}'
    for r in `seq 1 10`
    do
        for i in 1 2 4 8 16 32 64 128 256 512 1024
        do
            stress-ng --sem $i -t 10 --metrics 2> /dev/null | grep sem-posix | grep -v dispatching | awk '{print '$i', $0}'
            stress-ng --futex $i -t 10 --metrics 2> /dev/null | grep futex | grep -v dispatching | awk '{print '$i', $0}'
        done
    done

    exit
fi

if [ -f /usr/share/elasticsearch/bin/elasticsearch ]; then
    echo ========NOKML=========
    ./guest_load_entropy 1000
    sh guest_net.sh
    cd /usr/share/elasticsearch
    rm -rf /usr/share/elasticsearch/data/nodes/*
    export PATH=/usr/share/elasticsearch/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    export ELASTIC_CONTAINER=true
    export LD_LIBRARY_PATH=/usr/share/elasticsearch/jdk/lib
    mount proc /proc -t proc
    /sbin/sysctl fs.file-max=65535
    /sbin/sysctl fs.file-nr=65535
    ulimit -Hn 65535
    ulimit -Sn 65535
    /sbin/sysctl vm.max_map_count=262144
    echo cluster.initial_master_nodes: node-1 >> /usr/share/elasticsearch/config/elasticsearch.yml
    bash /usr/local/bin/docker-entrypoint.sh eswrapper
    exit
fi

if [ -d "/usr/src/wordpress" ]; then
    sh guest_net.sh
    ./guest_load_entropy
    echo ========NOKML=========
    bash /usr/local/bin/docker-entrypoint.sh apache2-foreground
    exit
fi

if which php; then
    echo ========NOKML=========
    ./guest_load_entropy 1000
    /usr/local/bin/php -r 'echo "hello\n";'
    exit
fi

if which mysql; then
    sh guest_net.sh
    echo ========NOKML=========
    MYSQL_ALLOW_EMPTY_PASSWORD=yes /entrypoint.sh mysqld
    exit
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
    exit
fi

if which mongo; then
    sh guest_net.sh
    echo ========NOKML=========
    /usr/local/bin/docker-entrypoint.sh mongod
    exit
fi

if which nginx; then
    sh guest_net.sh
    cp `which nginx` /trusted
    if echo $@ | grep trusted - > /dev/null; then
        echo ========KML=========
        /trusted/libc.so /trusted/nginx -g 'daemon off;error_log stderr debug;'
    else
        echo ========NOKML=========
        $@ -g 'daemon off;error_log stderr debug;'
    fi
    exit
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
    exit
fi
