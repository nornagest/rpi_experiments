#!/usr/bin/perl

use Modern::Perl 2013;
use warnings;

use DS18B20;
use AnyEvent;

my $ds18b20 = DS18B20->new();
my $exit_loop = AnyEvent->condvar;
my $w = AnyEvent->timer (
    after => 1, 
    interval => 300, 
    cb => sub { read_temp(); }
);

$exit_loop->recv; 


sub read_temp {
  for(@{$ds18b20->Sensors}) {
      my %temp = (
        "time" => scalar localtime(),
        "sensor" => $_->File,
        "value" => $_->get_temp(),
      );
      process_temp(\%temp);
  }
}
   
sub process_temp {
    my $temp = shift;
    print $temp->{"time"}, " ", $temp->{"sensor"}, " ", $temp->{"value"}, "°C\n";
}
