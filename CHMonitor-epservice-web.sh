#!/bin/bash

PREFIX=epsvc1_
FROM=/home/pbt/epservice-web/dumps/logs
TO=$FROM/old
DATE_NOW=$(date -u '+%Y%m%d_%H')
HOST=$(hostname)
RAID=raid
DEST=/raid/logs/com/epservice-web/dumps
mkdir -p ~/var/log/

function log(){
    dt=$(date "+%Y-%m-%d %H:%M:%S")
    printf "[$dt] $@\n" >>~/var/log/dump.log
}

## ARCHIVE
cd $FROM
for i in $(ls | egrep '[0-9]{8}\_[0-9]{6}\_[0-9]{3}'| sort | grep -v "$DATE_NOW"); do
    if [ -e "$i" ]; then
                dateRaw=${i:${#PREFIX}:11}
                dateCurrent=${dateRaw:0:4}-${dateRaw:4:2}-${dateRaw:6:2}-${dateRaw:9:2}
                if [ "$datePrev" != "$dateCurrent" ]; then
                    out=healthmonitor.$dateCurrent.$HOSTNAME.tgz
                    tar --remove-files -zcf $TO/$out $PREFIX$dateRaw*
                    datePrev=$dateCurrent
                fi
    fi
done

## TRANSFER
cd $TO
for i in $(ls *.tgz 2>/dev/null| sort ); do
    dateTo=$(echo $i | grep -Eo '[0-9]{4}(-[0-9]{2}){2}')
    transferTO=$DEST/$dateTo
    if [ ! -z "$dateTo" ]; then
                ssh $RAID -t "mkdir -p $transferTO" 2>/dev/null && \
                rsync -goaqz --bwlimit=300000 $i $RAID:$transferTO/ && rm -f $i && log "[TRANSFER] $i" || log "[FAILED] $i"
    fi
done
