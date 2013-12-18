#!/usr/bin/perl

use strict;
use warnings;

use DS18B20;

my $ds18b20 = DS18B20->new();

for(@{$ds18b20->Sensors}) {
  print $_->File, " ", $_->get_temp(),"\n";
}
