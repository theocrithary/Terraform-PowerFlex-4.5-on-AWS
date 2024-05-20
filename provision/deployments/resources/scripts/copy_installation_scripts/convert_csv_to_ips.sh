#!/bin/bash
COUNTER=1
sed "s/\\(IP_$COUNTER\\)/$1/g" /tmp/CSV_basic.csv > /tmp/temp$COUNTER.csv
for var in "${@:1}"
do
    TEMP_COUNTER=$(( COUNTER + 1 ))
    sed "s/\\(IP_$COUNTER\\)/$var/g" /tmp/temp$COUNTER.csv > /tmp/temp$TEMP_COUNTER.csv
    COUNTER=$(( COUNTER + 1 ))
done
cat /tmp/temp$COUNTER.csv > /tmp/core_deployment.csv
rm -rf /tmp/temp*
