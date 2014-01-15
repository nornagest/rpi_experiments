#!/usr/bin/perl

use Modern::Perl 2013;
use warnings;

use DS18B20;
use IO::Async::Listener;
use IO::Async::Loop;
use IO::Async::Timer::Periodic; 

my $ds18b20 = DS18B20->new();
my $loop = IO::Async::Loop->new;
my $timer = IO::Async::Timer::Periodic->new(
    interval => 300,
    first_interval => 1,
    on_tick => sub { 
        my $temp = read_temp(); 
        print_temp( $temp );
    },
);

$timer->start;
$loop->add( $timer );
$loop->run;

sub read_temp {
    my %temp = ("time" => scalar localtime());
    for(@{$ds18b20->Sensors}) {
        $temp{$_->File} = $_->get_temp();
    }
    return \%temp;
}

sub print_temp {
    my $temp = shift;
    for(keys %{$temp}) {
        print $_, " => ", $temp->{$_}, "\n";
    }
}

sub process_temp($) {
    my $temp = shift;
    print $temp->{"time"}, " ", $temp->{"sensor"}, " ", $temp->{"value"}, "°C\n";
}
