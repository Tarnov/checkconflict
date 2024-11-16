#!/bin/bash
awk '{if ($2+1 < 10) print (10-int($2+1))*10 "%" ; else print "0%" }' /proc/loadavg
