#!/usr/bin/env bash
LOG="/home/panbet/webmaster/newrelic/master/logs/newrelic_agent.log"
DATE=$(date '+%b %d, %G %H:%M')

if [ -n "$1" ]; then
  DATE="$1"
fi

FOUND=$(grep "$DATE" "$LOG"|grep 'WARN: Circuit breaker tripped at memory ')

if [ -n "$FOUND" ]; then
  echo "$FOUND"
fi

