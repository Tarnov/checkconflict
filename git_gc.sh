#!/bin/bash

PATH=$(find /home/mcore/ -maxdepth 3 -name ".git" -type d | grep build.conf)
for path in $PATH ; do 
	cd $path
    /usr/bin/git gc --quiet
done

