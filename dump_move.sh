#!/usr/bin/env bash

THREADS_DIR=${HOME}/server/dumps/logs
OUT_DIR=${HOME}/server/dumps/logs/old

host=$(hostname)
pwd=$(pwd);cd ${THREADS_DIR}
for i in $(find ${THREADS_DIR} -maxdepth 1 -cmin +120 -name "td_*" | sort | tr "\n" " ")
    do
    # do not create dir if files not found
    date=$(basename $i | cut -c 4-14);
    date_test=$(date --date "$(echo $date | tr "_" " ")" "+%Y%m%d %H") >/dev/null 2>/dev/null
        if [ $? -ne 0 ]; then continue; fi
    if [ "${date}" != "${date_packed}" ]; then
        mkdir -p ${OUT_DIR}
        nice -n19 tar --remove-files -czvf ${OUT_DIR}/td.$(echo -n "${date:0:4}-${date:4:2}-${date:6:2}-${date:9:2}").${host}.tar.gz td_${date}*
        date_packed=${date}
    fi
    done
cd ${pwd}
