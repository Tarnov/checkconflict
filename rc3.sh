#!/bin/bash


git fetch -p
LAST_BUILD_VERSION=$(git tag | egrep '^build/[0-9+].[0-9]+.[0-9]+$' | tail -2 | head -1)
git tag | grep build/ | while read tag; do
    echo $tag | grep -q $LAST_BUILD_VERSION && exit || {
        echo $tag | egrep -q "build/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" && {
            git tag -d $tag
            git push origin :refs/tags/$tag
        } || continue
    }
done
