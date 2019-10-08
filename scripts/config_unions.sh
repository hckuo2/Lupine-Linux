#!/bin/bash

#ordered by stars
APP[0]=nginx
APP[1]=mysql
APP[2]=node
APP[3]=redis
APP[4]=postgres
APP[5]=mongo
APP[6]=php
APP[7]=python
APP[8]=elasticsearch
APP[9]=wordpress
NUM_APPS=10

for ((i=0;i<$NUM_APPS;i++)); do
    echo -n "$((i+1)) "
    for ((j=0;j<=$i;j++)); do
        cat configs/apps/${APP[$j]}.config | grep "^CONFIG";
    done | sort | uniq | wc -l 
done
