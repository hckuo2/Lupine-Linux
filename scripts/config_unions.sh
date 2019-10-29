#!/bin/bash

APP[0]=wordpress
APP[1]=elasticsearch
APP[2]=go
APP[3]=haproxy
APP[4]=hello-world
APP[5]=httpd
APP[6]=influxdb
APP[7]=mariadb
APP[8]=memcached
APP[9]=mongo
APP[10]=mysql
APP[11]=nginx
APP[12]=node
APP[13]=openjdk
APP[14]=php
APP[15]=postgres
APP[16]=python
APP[17]=rabbitmq
APP[18]=redis
APP[19]=traefik

NUM_APPS=20

for ((i=0;i<$NUM_APPS;i++)); do
    echo -n "$((i+1)) "
    for ((j=0;j<=$i;j++)); do
        cat configs/apps/${APP[$j]}.config | grep "^CONFIG";
    done | sort | uniq | wc -l 
done
