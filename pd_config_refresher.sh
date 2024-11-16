#!/bin/bash

DOMAIN=$(curl -s http://etcd.ggs.local:2379/v2/keys/mirrors/curacao/www/published | grep -oP "(?<=www\.)[.a-z0-9-]*(?=/)")
REPO="ssh://git@stash.mhd.local:7999/kaelthas/punterdomain-config.git"
REPODIR="/tmp/punterdomain-config"

if [ -d $REPODIR/.git ];
then
    git --git-dir=$REPODIR/.git/ --work-tree=$REPODIR pull stash master &> /dev/null
else
    mkdir -p $REPODIR
    git clone -o stash $REPO $REPODIR
fi

OLDDOMAIN=$(grep -oP "(?<=alias: www\.)[.a-z0-9-]*"  $REPODIR/domains.cfg.yml | head -1)
        
if [ "$DOMAIN" != "$OLDDOMAIN" ] && [ -n "$DOMAIN" ] && [ -n "$OLDDOMAIN" ];
then
    sed -i "s/$OLDDOMAIN/$DOMAIN/g" $REPODIR/domains.cfg.yml
    git --git-dir=$REPODIR/.git/ --work-tree=$REPODIR commit -am "$DOMAIN" &> /dev/null
    git --git-dir=$REPODIR/.git/ --work-tree=$REPODIR push stash master &> /dev/null
    sleep 1m
    for i in 1 2;
    do
        curl -s -X POST "punterdomain$i.knk.local:8080/refresh"
        curl -s -X POST --data '[ "'"www.${OLDDOMAIN}"'" ]' -H "Content-Type:application/json" http://punterdomain.knk.local:8080/domain/addBlockedDomains >/dev/null 2>&1
        
    done
    echo "$OLDDOMAIN -> $DOMAIN" | mail -s "Активное зеркало изменено на $DOMAIN" -t duty-admin@marathonbet.ru
fi
