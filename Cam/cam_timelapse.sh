#!/bin/bash
DIR=/usr/share/motion
while [ true ]; do                                                       
filename=$(date -u +"%Y%m%d-%H%M-%S").jpg                                       
/opt/vc/bin/raspistill -o $DIR/$filename -w 2592 -h 1944 -rot 270 -n -t 5000
echo "$DIR/$filename written"
sleep 60;
done
