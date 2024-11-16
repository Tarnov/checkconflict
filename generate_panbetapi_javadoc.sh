#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail
set -o errtrace
set -o functrace


# Set VARs
RELEASE_VERSION=$1
WORK_DIR=$2


# Prepate working directory
rm -rfv ${WORK_DIR} ${WORK_DIR}.zip
mkdir ${WORK_DIR}


# Prepare HTML header
cat << EOF > ${WORK_DIR}/index.html
<!DOCTYPE html>
<html>
        <head>
                <title>PANBETAPI JAVADOC $1</title>
                <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
                <style>
                        h1 { font-size: 50px; }
                        body { text-align:center; font: 20px Helvetica, sans-serif; color: #333; }
                </style>
        </head>
        <body>
                <h1>$1</h1>
		<table style="margin: auto">
			<tr>
EOF

i=0
cat panbetapi-parent/pom.xml | grep '<module>' | grep -v 'panbetapi' | grep -v 'config' | sed -r 's|.*>(.*)<.*|\1|' | sort -n | while read orig_string; do
        string=$orig_string
        if [ "$string" == "flatbetting" ]; then
                string="flat-betting"
        fi
	if [ "$string" == "paydeskbetting" ]; then
		continue;
	fi
        version=$(cat pom.xml | grep "<$string-api-version" | sed -r 's|.*>(.*)<.*|\1|')
        string=$orig_string	
	echo $string-$version
	if [ "$string" == "externalbetting" ]; then
		string="externalbetting-api"
	fi
	if [ "$string" == "member" ]; then
                string="panbet-member-api"
        fi
	if [ "$string" == "puntercontrol" ]; then
                string="panbet-puntercontrol"
        fi
        if [ "$string" == "credit" ]; then
                string="panbet-credit-api"
        fi
	wget -c http://artifactory.mara.local/artifactory/repo/com/panbet/api/$string/$version/$string-$version-javadoc.jar --directory-prefix=${WORK_DIR} || exit 1
	rm -rfv ${WORK_DIR}/$string
	unzip ${WORK_DIR}/$string-$version-javadoc.jar -d ${WORK_DIR}/$string
	rm -rfv ${WORK_DIR}/$string-$version-javadoc.jar
	if [ "$(($i % 3))" == "0" ]; then
		echo "</tr><tr>" >> ${WORK_DIR}/index.html
	fi
	echo "<td><p><a href=\"$string/index.html\">$string-$version</a></p></td>" >> ${WORK_DIR}/index.html
	i=$(($i + 1))
done

# Finalize HTML sctructure
cat << EOF >> ${WORK_DIR}/index.html
			</tr>
		</table>
	</body>
</html>
EOF


# Archive resulting site
zip -r ${WORK_DIR}.zip ${WORK_DIR}/

