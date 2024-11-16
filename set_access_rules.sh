#!/bin/bash

function ulog(){
    local ldate input="$@"
    if [ -z "$input" ]; then input=$(cat); fi
    if [ -n "$input" ];
    then
        ldate=$(date "+%Y-%m-%d %H:%M:%S")
        echo "$ldate $input" >> $LOG
    fi
}

usage() {
    echo "Usage: $0 -f
    filelist format: /full/path/to/file;mode;user:group"
    exit 1
}

LOG="$HOME/var/log/set_access_rules.log"
REPO="ssh://stash.mhd.local:7999/pconf/all-acess_rules_list.git"
FILENAME="filelist"

set -o pipefail

if [ -z $1 ]; then 
    usage
fi

if [ $1 = "-f" ]
then
    DIR=$(mktemp -d)
    cd $DIR
    git clone "$REPO" ${REPO##*/}
    cd - > /dev/null
    FILELIST=$DIR/${REPO##*/}/$FILENAME

    while IFS=';' read -a line || [[ -n "$line" ]]; do
        file=${line[0]}
        mode=${line[1]}
        owner_group=${line[2]}
        if [ -z $file ] ; then continue ; fi
        if [ -e $file -a ! -L $file ] 
            then
                chmod -v $mode "$file" 2>/dev/null | awk '{if ($4=="changed")  print}' | ulog
                chown -v $owner_group "$file" 2>/dev/null | awk '{if ($1=="changed")  print}' | ulog
                if [ $? -ne 0 ] ; then 
                    owner=$(stat $file -c %U)
                    group=$(stat $file -c %G)
                    if [ ${owner_group%%:*} != $owner ] ; then
                        echo "$file owner '$owner' but '${owner_group%%:*}' needed" | ulog
                    fi
                    if [ ${owner_group##*:} != $group ] ; then
                        echo "$file group '$group' but '${owner_group##*:}' needed" | ulog
                    fi
                fi
        fi
    done < "$FILELIST"
    rm -rf $DIR
fi
