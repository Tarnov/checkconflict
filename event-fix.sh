#!/bin/bash
USER_NAME="panbet"
RAID_HOST="raid.mhd.local"
WORKDIR=$(dirname $(readlink -e "$0"))
DBUPDATE="$WORKDIR/dbupdate/run_dbupdate.sh"
FILE_REPLICATE="$WORKDIR/replicated"
MAGIC_WORD="StArT"
LOG="$WORKDIR/eventfix.log"

function Log {
 echo $(date '+%D %H:%M:%S') $* >> $LOG
}

########## < START SCRIPT > ##########
Log "[$$] Getting lost events"

### Once a day remove file replicate
if [ $(date +%H) -eq 1 ]; then
  if [ -r $FILE_REPLICATE ]; then
    Log "[$$] Remove file replicate"
    rm $FILE_REPLICATE
  fi
fi

result=$(ssh -T $USER_NAME@$RAID_HOST << "EOF"
LOGDIRS=$(for i in $(seq 2 -1 0); do echo /raid/logs/es/server/$(date -d "now -$i days" +%Y-%m-%d); done)
echo "StArT"
for LOGDIR in $LOGDIRS; do ls -1t $LOGDIR/errorLB.*.app[1-2]-es.gz | head -10 | xargs zcat | grep 'ERROR Command Command=ReplicationProcessMessage' | grep -v 'rep-replication.archive' | grep -Po '(?<=Event with externalId = )[0-9]+' | sort | uniq | tr '\n' ' '; done
EOF
)

n=$(grep -n "$MAGIC_WORD" <<< "$result"|cut -f1 -d":")
lost_events=$(echo "$result" | sed -n $[$n +1]p)

if [ "${#lost_events}" -gt "2" ]; then
  Log "[$$] Found lost events: $lost_events"
else
  Log "[$$] Lost events not found"
  exit 0
fi

### Loading aliready replicated events
if [ -f "$FILE_REPLICATE" ]; then
  replicated=$(cat $FILE_REPLICATE)
fi

### Filter new missing events and create event list to resend it
new_lost_events=""
for event in $lost_events; do
  if [ -z "$(grep " $event " <<< " $replicated ")" ]; then
    new_lost_events="$new_lost_events $event"
  fi
done

## send_eventfix baby
if [ "${#new_lost_events}" -gt "1" ]; then
  Log "[$$] New lost events:$new_lost_events"
  Log "[$$] Running DBupdate"
  $DBUPDATE "send_eventfix $new_lost_events" >> $WORKDIR/dbupdate.log 2>> $WORKDIR/dbupdate.error.log
  Log "[$$] Update file replicate"
  replicated="$replicated$new_lost_events"
  echo $replicated > $FILE_REPLICATE
else
  Log "[$$] New lost events not found"
fi
