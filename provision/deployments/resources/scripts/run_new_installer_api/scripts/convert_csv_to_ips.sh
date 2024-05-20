#!/bin/bash
COUNTER=1
sed "s/\\(IP$COUNTER\\)/$1/g" ./CSV_basic.csv > ./temp$COUNTER.csv
for var in "${@:1}"
do
    TEMP_COUNTER=$(( COUNTER + 1 ))
    sed "s/\\(IP$COUNTER\\)/$var/g" ./temp$COUNTER.csv > ./temp$TEMP_COUNTER.csv
    COUNTER=$(( COUNTER + 1 ))
done
cat ./temp$COUNTER.csv > ./core_deployment.csv
rm -rf ./temp*
