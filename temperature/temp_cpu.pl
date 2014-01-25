#!/usr/bin/perl

use Modern::Perl 2013;

my $file = '/sys/class/thermal/thermal_zone0/temp';
open(my $fh, "<", $file) or die "Error opening $file.\n";
my $temp = <$fh>;
$temp =~ s/(\d{2})(\d{3})/$1\.$2°C/;
print "CPU temperature: $temp";
