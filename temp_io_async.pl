#!/usr/bin/perl

use Modern::Perl 2013;
use warnings;

use DS18B20;

use IO::Async::Timer::Periodic; 
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;
my $ds18b20 = DS18B20->new();

sub read_temp {
  for(@{$ds18b20->Sensors}) {
    print scalar localtime(), " ", $_->File, " ", $_->get_temp(), "°C\n";
  }
}
   
 
my $timer = IO::Async::Timer::Periodic->new(
   interval => 200,
   first_interval => 1,
 
   on_tick => sub {
     read_temp();
   },
);
 
$timer->start;
 
$loop->add( $timer );
 
$loop->run;
