#!/bin/sh
export PATH="/usr/local/bin:$PATH"
mkdir -p /trusted
mount -t proc proc /proc
ulimit -n 65535

echo "APP START"

if [ -f /usr/bin/influxd ]; then
	sh guest_net.sh
	sh /init-influxdb.sh
	/usr/bin/influxd
	exit
fi

if [ -f /opt/rabbitmq/sbin/rabbitmq-server ]; then
	sh guest_net.sh
	mkdir -p /var/lib/rabbitmq
	mkdir -p /rabbitmq-env
	/load_entropy
	export PATH=/opt/rabbitmq/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
	export OPENSSL_VERSION=1.1.1d
	export OPENSSL_SOURCE_SHA256=1e3a91bc1f9dfce01af26026f856e064eab4c8ee0a8f457b5ae30b40b8b711f2
	export OPENSSL_PGP_KEY_IDS=0x8657ABB260F056B1E5190839D9C4D26D0E604491
	export OTP_VERSION=22.1.4
	export OTP_SOURCE_SHA256=982e940c8c3313b1af27938655b4e90991d54bd6720b238c25438c16bc51699f
	export RABBITMQ_DATA_DIR=/var/lib/rabbitmq
	export RABBITMQ_VERSION=3.8.0
	export RABBITMQ_PGP_KEY_ID=0x0A9AF2115F4687BD29803A206B73A36E6026DFCA
	export RABBITMQ_HOME=/opt/rabbitmq
	export RABBITMQ_LOGS=-
	export RABBITMQ_SASL_LOGS=-
	export HOME=/var/lib/rabbitmq
	export LANG=C.UTF-8
	export LANGUAGE=C.UTF-8
	export LC_ALL=C.UTF-8

	export RABBITMQ_DEFAULT_PASS=
	export LC_ALL=C.UTF-8
	export RABBITMQ_SSL_FAIL_IF_NO_PEER_CERT=true
	export LANG=C.UTF-8
	export HOSTNAME=d9975fcce12b
	export OPENSSL_VERSION=1.1.1d
	export OTP_VERSION=22.1.4
	export RABBITMQ_SASL_LOGS=-
	export RABBITMQ_HOME=/opt/rabbitmq
	export RABBITMQ_MANAGEMENT_SSL_FAIL_IF_NO_PEER_CERT=false
	export RABBITMQ_MANAGEMENT_SSL_VERIFY=verify_none
	export RABBITMQ_LOGS=-
	export RABBITMQ_VERSION=3.8.0
	export RABBITMQ_DATA_DIR=/var/lib/rabbitmq
	export RABBITMQ_SSL_VERIFY=verify_peer
	export RABBITMQ_PGP_KEY_ID=0x0A9AF2115F4687BD29803A206B73A36E6026DFCA
	export SHLVL=1
	export LANGUAGE=C.UTF-8
	export OPENSSL_SOURCE_SHA256=1e3a91bc1f9dfce01af26026f856e064eab4c8ee0a8f457b5ae30b40b8b711f2
	export RABBITMQ_DEFAULT_USER=
	export PATH=/opt/rabbitmq/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
	export OTP_SOURCE_SHA256=982e940c8c3313b1af27938655b4e90991d54bd6720b238c25438c16bc51699f
	
	echo 127.0.0.1    d9975fcce12b > /etc/hosts
	docker-entrypoint.sh rabbitmq-server
	exit
fi

if [ -f /usr/lib/jvm/java-1.8-openjdk/bin/javac ]; then
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin
    export LANG=C.UTF-8
    export JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk
    export JAVA_VERSION=8u171
    echo "class HelloWorld { public static void main(String args[]) {System.out.println(\"Hello, World\");}}"  > hello.java
    javac hello.java
    java HelloWorld
    exit
fi

if which mysqld; then
    sh guest_net.sh
    export MYSQL_ALLOW_EMPTY_PASSWORD=1
    /load_entropy 1000
    rm -f /var/lib/mysql/aria_log_control /ibdata1
    /docker-entrypoint.sh mysqld
    exit
fi

if which postgres; then
    sh guest_net.sh
    echo ========NOKML=========
    export MYSQL_ROOT_PASSWORD=mysecretpassword
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

if [ -f /usr/local/go/bin/go ]; then
    echo "package main" >> test.go
    echo "func main() {}" >> test.go
    /usr/local/go/bin/go build test.go
    ./test
    exit
fi

if [ -f /usr/local/bin/traefik ]; then
    sh guest_net.sh
    /usr/local/bin/traefik
    exit
fi

if [ -f /usr/local/bin/memcached ]; then
    sh guest_net.sh
    /usr/local/bin/memcached -u memcache -m 1024 -l 192.168.100.2 -p 11211
    exit
fi

if [ -f /usr/local/apache2/bin/httpd ]; then
    export PATH=/usr/local/apache2/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    export HTTPD_PREFIX=/usr/local/apache2
    export HTTPD_VERSION=2.4.41
    export HTTPD_SHA256=133d48298fe5315ae9366a0ec66282fa4040efa5d566174481077ade7d18ea40
    sh guest_net.sh
    ./guest_load_entropy
    cd /usr/local/apache2
    httpd-foreground

    exit
fi

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
