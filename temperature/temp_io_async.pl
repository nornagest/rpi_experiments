#!/usr/bin/perl

use Modern::Perl 2013;
use warnings;

use DS18B20;
use IO::Async::Listener;
use IO::Async::Loop;
use IO::Async::Timer::Periodic; 
use Storable qw(nfreeze);

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

#TODO: Auslagern und Strukturieren
# danach: Teil von RPiManager machen
$loop->listen(
    service  => 12345,
    socktype => 'stream',

    on_stream => sub {
        my ($stream) = @_;
        $stream->configure( on_read => sub { ${$_[1]} = ""; return 0; } );
        $loop->add( $stream );
        my $temp = read_temp();
	$temp = nfreeze($temp);
        $stream->write($temp);
        $stream->close_when_empty; #TODO: test this
    },

    on_closed => sub {
        print "Connection closed.\n";
    },

    on_resolve_error => sub { print STDERR "Cannot resolve - $_[0]\n"; },
    on_listen_error  => sub { print STDERR "Cannot listen\n"; },
);

$timer->start;
$loop->add( $timer );
$loop->run;

sub read_temp {
    #TODO: Make temp a class, so can handle it easier
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
