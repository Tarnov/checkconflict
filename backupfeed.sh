#!/bin/bash

FEED_DIR="/home/pbt/feedloader/feedarchive"
filelist=$(mktemp)
RAID="raid"
DESTINATION=/raid/feedloader/new_feedarchive

for dir in dogracing horseracing
do
	cd ${FEED_DIR}/${dir} || exit 1
	find . -type f -mtime -1 > ${filelist}
	dates=$(cat ${filelist} | grep -oE "/[a-z]{,1}20[0-9]{6}" | grep -oE "[0-9]{8}" | sort -u)
	for d in $dates
	do
		if [ -n "${d}" ]
		then
			fullDate=$(date -d ${d} +%F)
			remURL=${DESTINATION}/${dir}/${fullDate}
			ssh $RAID -t "mkdir -p $remURL" >/dev/null 2>&1
			cat $filelist | grep -E "/[a-z]{,1}${d}" | rsync -au --files-from=- ${FEED_DIR}/${dir}/ $RAID:$remURL
		fi
	done
done
rm ${filelist}
