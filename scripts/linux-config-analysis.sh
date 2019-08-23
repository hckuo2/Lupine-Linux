#!/bin/bash

find linux/ -name "Kconfig*" -exec "grep" "-Hn" "config [A-Z0-9]" "{}" ";" > /tmp/c

TOTAL=`cat /tmp/c | wc -l`

echo "=====TOTAL====="
for f in linux `cat /tmp/c | cut -f 1,2 -d '/'| sort | uniq | grep -v Kconfig`; do
    echo -n "$f "
    cat /tmp/c | grep $f/.*Kconfig | wc -l
done

# get rid of non x86 arches for the next part
cat /tmp/c | grep -v "arch/alpha" \
    | grep -v "arch/arc" \
    | grep -v "arch/arm" \
    | grep -v "arch/arm64" \
    | grep -v "arch/avr32" \
    | grep -v "arch/blackfin" \
    | grep -v "arch/c6x" \
    | grep -v "arch/cris" \
    | grep -v "arch/frv" \
    | grep -v "arch/hexagon" \
    | grep -v "arch/ia64" \
    | grep -v "arch/m32r" \
    | grep -v "arch/m68k" \
    | grep -v "arch/metag" \
    | grep -v "arch/microblaze" \
    | grep -v "arch/mips" \
    | grep -v "arch/mn10300" \
    | grep -v "arch/nios2" \
    | grep -v "arch/openrisc" \
    | grep -v "arch/parisc" \
    | grep -v "arch/powerpc" \
    | grep -v "arch/s390" \
    | grep -v "arch/score" \
    | grep -v "arch/sh" \
    | grep -v "arch/sparc" \
    | grep -v "arch/tile" \
    | grep -v "arch/um" \
    | grep -v "arch/unicore32" \
    | grep -v "arch/x86/um" \
    | grep -v "arch/xtensa" \
           > /tmp/c2

for s in configs/microvm.config configs/lupine-djw-nokml.config; do
    echo "===== $s ====="

    for c in `cat $s |grep -v "^#" | grep -v "^$" | cut -f 1 -d '=' | cut -f 2- -d '_'`; do
#    echo -n "=======$c=========="
        cat /tmp/c2 | grep "config $c\$" 
    done > /tmp/c3
    
    for f in linux `cat /tmp/c3 | cut -f 1,2 -d '/'| sort | uniq | grep -v Kconfig`; do
        echo -n "$f "
        cat /tmp/c3 | grep $f/.*Kconfig | wc -l
    done
done
