#!/usr/bin/perl
select STDOUT;
$|=1;
print "Content-type: image/jpeg\n\n";

system "/opt/vc/bin/raspistill -t 2000 -ex night -rot 270 -o -";
