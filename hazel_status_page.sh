#!/usr/bin/env bash

PORT="8080"
R_200="HTTP/1.1 200 OK\n\n"
R_503="HTTP/1.1 503 BAD\n\n"
STATUS_FILE="/home/panbet/var/hazelcast_status"
PID_FILE="/home/panbet/var/hazelcast_status_page.pid"
COUNTER=1

if [ -s "$PID_FILE" ] && [ -w "$PID_FILE" ]; then 
  PID=$(cat $PID_FILE)
  if [ -e "/proc/$PID" ]; then
    kill -9 $PID
  fi
fi

while true; do
  curl -I http://127.0.0.1:$PORT -s > /dev/null
  if [ "$?" = "0" ]; then
    sleep $COUNTER
    ((COUNTER++))
  if [ "$COUNTER" -ge "5" ]; then 
    exit 1;
  fi
  else
    break;
  fi
done

echo $$ > $PID_FILE

while true; do
  if [ -e "$STATUS_FILE" ]; then
     VAL=$(cat $STATUS_FILE)
     echo -e "${R_200}${VAL}" | nc -l -p $PORT -w 1 > /dev/null;
     if [ "$?" -ne "0" ]; then
       exit 1
     fi
  else
     echo -e "${R_503}Error" | nc -l -p $PORT -w 1 > /dev/null;
     if [ "$?" -ne "0" ]; then
       exit 1
     fi  
  fi
done
