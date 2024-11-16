#!/bin/bash

VERSION=$(git tag | egrep '^build/[0-9+].[0-9]+.[0-9]+$' | tail -3 | head -1 | cut -f2 -d'/'); for version in $(curl -s http://artifactory.mara.local/artifactory/list/libs-release-local/bamboo-builds/panbet/ | grep $VERSION | sed -r 's|.*>(.*)/<.*|\1|'); do echo -n "Deleting $version... ";  curl -u tarnov.s:apgc8gk|nxGr2cHOZbWoro#hx{?C?Z?g320s9GdXU3pmC -X DELETE "http://artifactory.mara.local/artifactory/libs-release-local/bamboo-builds/panbet/$version"; echo Done; done
