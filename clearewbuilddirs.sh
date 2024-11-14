#!/bin/bash
BAMBOO_BUILDDIR="/home/bamboo/bamboo-agent-home/xml-data/build-dir"
find ${BAMBOO_BUILDDIR} -maxdepth 1 -type d -ctime +1 | xargs rm -rf
EW_MAIN_BUILD="MPS-EWDEVELOPMENT*-JOB1"

# 2G == 2M kilobyte
MAX_SIZE="2097152"

EW_BUILD_DIRS="${BAMBOO_BUILDDIR}/${EW_MAIN_BUILD}"

for buildDir in ${EW_BUILD_DIRS}
do
  vol=`du -s $buildDir | awk '{print $1}'`

  if [ ${vol} -gt ${MAX_SIZE} ]
  then
    echo "Size of \"${buildDir}\" is ${vol}, exceed ${MAX_SIZE}, start clean"

    cd $buildDir

    echo "Clean service dir"
    rm ./service/*

    echo "Clean build dir in $buildDir"

    for subBuildDir in ./*
    do
      echo "Try clean ${subBuildDir}"
      if [ -f ${subBuildDir}/pom.xml ]
      then
        cd ${subBuildDir}
        echo "Run maven clean in ${subBuildDir}"
        mvn -q clean
        cd  ..
      else
        echo "No pom.xml in ${subBuildDir}, skip clean"
      fi
    done

  else
    echo "Size of \"${buildDir}\" is ${vol}, does not exceed ${MAX_SIZE}, skip clean"
  fi
done
