#!/usr/bin/perl

use Modern::Perl 2013;
use warnings;

use DS18B20;
use IO::Async::Timer::Periodic; 
use IO::Async::Loop;

my $ds18b20 = DS18B20->new();
my $loop = IO::Async::Loop->new;
my $timer = IO::Async::Timer::Periodic->new(
    interval => 300,
    first_interval => 1,
    on_tick => sub { read_temp(); },
);

$timer->start;
$loop->add( $timer );
$loop->run;


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
