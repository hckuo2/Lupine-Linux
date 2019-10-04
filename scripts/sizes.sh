#!/bin/bash

APPS="php python node wordpress mysql mongo postgres elasticsearch redis nginx"
OTHER="no-dev-multi no-dev"
BASE="lupine-djw"
BASEOPTS="-kml -nokml -kml-tiny -nokml-tiny"

get_size() {
    ls -l kernelbuild/$1/vmlinux  2>/dev/null | cut -f 5 -d ' '
}
get_app_size() {
    echo $(get_size "$BASE$1++$2")
}
get_config_size() {
    cat configs/$1.config | grep "^CONFIG" | wc -l
}



for a in $APPS; do
    for o in $BASEOPTS; do
        s=$(get_app_size $o $a)
        echo "$s $a $o"
    done
done | sort -n


echo
p=`echo "scale=4; ($(get_size microvm)/$(get_size defconfig).0)*100" | bc`
echo "microvm is $p % of defconfig"


echo
echo "Tiny savings on base:"
d="$(($(get_size "$BASE-nokml") - $(get_size "$BASE-nokml-tiny")))"
p=`echo "scale=4; ($d/$(get_size "$BASE-nokml").0)*100" | bc`
echo "$a $d bytes ( $p % )"
d="$(($(get_size "$BASE-kml") - $(get_size "$BASE-kml-tiny")))"
p=`echo "scale=4; ($d/$(get_size "$BASE-kml").0)*100" | bc`
echo "$a $d bytes ( $p % )"

echo
echo "Tiny saves between:"
for a in $APPS; do
    d="$(($(get_app_size "-nokml" $a) - $(get_app_size "-nokml-tiny" $a)))"
    p=`echo "scale=4; ($d/$(get_app_size "-nokml" $a).0)*100" | bc`
    echo "$a $d bytes ( $p % )"
    d="$(($(get_app_size "-kml" $a) - $(get_app_size "-kml-tiny" $a)))"
    p=`echo "scale=4; ($d/$(get_app_size "-kml" $a).0)*100" | bc`
    echo "$a $d bytes ( $p % )"
done |sort -n -k5 | sed -e 1b -e '$!d'

echo
echo "KML saves between:"
for a in $APPS; do
    d="$(($(get_app_size "-nokml" $a) - $(get_app_size "-kml" $a)))"
    echo "$a $d bytes"
done |sort -n -k 2| sed -e 1b -e '$!d'

echo
echo "Fraction of microvm between:"
for a in $APPS; do
    p=`echo "scale=4; ($(get_app_size "-kml" $a).0/$(get_size microvm))*100" | bc`
    echo "$a $p %"
done | sort -n -k 2 | sed -e 1b -e '$!d'

echo
echo "Amount over base between:"
for a in $APPS; do
    p=`echo "scale=4; ($(get_app_size "-kml" $a).0/$(get_size $BASE-kml))*100" | bc`
    echo "$a $p %"
done | sort -n -k 2 | sed -e 1b -e '$!d'

echo
echo "# config size vs. image size:"
for a in $APPS; do
    p=`echo "scale=4; ($(get_app_size "-kml" $a).0/$(get_size $BASE-kml))*100 - 100" | bc`
    echo "$a $(get_config_size $a) $p"
done | sort -n -k 2


