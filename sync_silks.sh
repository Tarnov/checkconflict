#!/bin/bash

# Script is already starting
NAME=$(basename $0)
if [ "$(pgrep $NAME)" != "$$" ]; then exit 0; fi

APPPATH="/home/panbet/server/tomcat/server/webapps/images/horses"
HTTPPATH="/opt/httpd/images/horses"
USER="root"
HTTPSERVERS=( http1.mhd.local \
	      http2.mhd.local \
	      http3.mhd.local \
	      http4.mhd.local \
	      http1.knk.local \
	      http2.knk.local \
	      http3.knk.local \
	      http4.knk.local)
#	      213.184.248.37 )

FTPPATH="/home/pasports"
FTPUSER="pasports"
FTP="172.16.10.50"

echo " "
/bin/date
echo " "

	echo "Remove old files in $APPPATH"
	`find $APPPATH -name '*.png' -mtime +30 -exec rm {} \; && find $APPPATH -depth -type d -empty -exec rmdir {} \;`
	echo "========================================================"

#	echo "Remove old files in $FTP:$FTPPATH"
#	ssh $FTPUSER@$FTP 'find $FTPPATH \( -name "*.xml" -o -name "*.tgz" \) -mtime +30 -exec rm {} \;'
#	echo "========================================================"

for i in ${HTTPSERVERS[@]}
do
	echo "rsync images app0 > $i"
	/usr/bin/rsync -goavz $APPPATH $USER@$i:$HTTPPATH/..
	echo "========================================================"
done

