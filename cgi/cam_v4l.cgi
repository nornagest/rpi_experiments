#!/usr/bin/perl
select STDOUT;
$|=1;
print "Content-type: image/jpeg\n\n";

system "v4l2-ctl --set-fmt-video=width=2592,height=1944,pixelformat=3";
system "v4l2-ctl --stream-mmap=3 --stream-count=1 --stream-to=-";
