#!/usr/bin/env bash

STATUS_FILE="/home/panbet/var/hazelcast_status"
host="localhost:11021"
jar="/home/panbet/bin/jmxterm-1.0-alpha-4-uber.jar"

#echo "get -s -b com.hazelcast:type=Cluster,name=_hzInstance_1_PanbetWebKNK MemberCount"| java -jar jmxterm-1.0-alpha-4-uber.jar -l hazelcast1.knk.local:11021 -v silent -n
cmd="get -s -b com.hazelcast:type=Cluster,name=_hzInstance_1_PanbetWebKNK MemberCount Members"

VALUE=$(echo ${cmd} | java -jar ${jar} -l ${host} -n -v silent 2> /dev/null)
if [ "$?" == "0" ]; then
  echo "${VALUE}" > "$STATUS_FILE"
else
  if [ -e "$STATUS_FILE" ]; then
     rm "$STATUS_FILE"
  fi
fi
