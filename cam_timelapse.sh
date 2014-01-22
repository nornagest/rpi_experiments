#!/bin/bash
DIR=/usr/share/nginx/img
x=1
while [ $x -le 132 ]; do                                                       
filename=$(date -u +"%Y%m%d-%H%M-%S").jpg                                       
raspistill -o $DIR/$filename -w 1280 -h 960 -rot 90 -n -t 1000
x=$(( $x + 1 ))
sleep 300;
done
