#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: rrd_client.pl
#
#        USAGE: ./rrd_client.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hagen Kuehl (), nornagest[at]gmx.de
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 11/11/2014 06:41:51 AM
#     REVISION: ---
#===============================================================================

use Modern::Perl 2013;
use IO::Async::Loop;
use IO::Async::Stream;
use IO::Async::Timer::Periodic;
use Storable qw(nfreeze);
use Data::Dumper;

use DataSource::CPU;

my $host = 'feanor';
my $server = 'feanor';
my $port = 12346;
my @sources;

my $loop = IO::Async::Loop->new;
init();
$loop->run;

sub init {
    #my @cpus = DataSource::CPU->get_sensors();
    #for(@cpus) {
    #    push @sources,  DataSource::CPU->new(name => $_);
    #}
    my @ds18b20 = DataSource::CPU->get_sensors();
    for(@ds18b20) {
        push @sources,  DataSource::DS18B20->new(name => $_);
    }

    my $timer = IO::Async::Timer::Periodic->new(
        interval => 30,
        first_interval => 1,
        on_tick => sub { on_tick(); },
    );
    $timer->start;
    $loop->add($timer);
}

sub on_tick {
    my $message = create_message(\@sources);
    connect_and_send($message);
}

sub create_message {
    my $sources = shift;
    my $message = { host => $host, data => [] };
    for(@{$sources}) {
        push @{$message->{'data'}}, { 
            ds => {
                name => $_->name,
                type => $_->type,
                description => $_->description, 
            },
            value => $_->get_value(), 
            time => time() 
        };
    }
    return $message;
}

sub connect_and_send { 
    my $message = shift;
    $loop->connect(
        host     => $server,
        service  => $port,
        socktype => 'stream',

        on_stream => sub { send_message($_[0], $message); },
        on_closed => sub { print "Connection closed.\n"; },
        on_resolve_error => sub { warn "Cannot resolve - $_[0]\n" },
        on_connect_error => sub { warn "Cannot connect\n" },
    );
}

sub send_message {
    my ($stream, $message) = @_;
    #don't expect client input
    $stream->configure( on_read => sub { ${$_[1]} = ""; return 0; } );
    $loop->add( $stream );
    say Dumper($message);
    $message = nfreeze(\$message);
    $stream->write($message);
    $stream->close_when_empty; 
}
