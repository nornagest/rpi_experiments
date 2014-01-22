#!/bin/bash
DIR=/home/nornagest/cam
x=1
while [ $x -le 60 ]; do                                                       
filename=$(date -u +"%Y%m%d-%H%M-%S").jpg                                       
raspistill -o $DIR/$filename -w 1280 -h 960 -n -t 1000
x=$(( $x + 1 ))
sleep 300;
done
