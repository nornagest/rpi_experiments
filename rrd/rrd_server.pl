#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: rrd_server.pl
#
#        USAGE: ./rrd_server.pl  
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
#      CREATED: 11/11/2014 06:41:41 AM
#     REVISION: ---
#===============================================================================

use Modern::Perl 2013;
use IO::Async::Listener;
use IO::Async::Loop;
use IO::Async::Timer::Periodic; 
use Storable qw(thaw);
use RRDTool::OO;
use Data::Dumper;
use RRD;
use DataSource;

###
my $datasource = DataSource->new(
    name => 'CPU1', 
    type => 'DataSource::CPU', 
    description => 'Just a dummy'
);
my $rrd = RRD->new(name => 'test', datasources => [$datasource]);
###
my $port = 12346;

my $loop = IO::Async::Loop->new;
my $timer = IO::Async::Timer::Periodic->new(
    interval => 60,
    first_interval => 1,
    on_tick => sub { 
        draw_graphs();
    },
);

$timer->start;
$loop->add( $timer );

$loop->listen(
    service  => $port,
    socktype => 'stream',

    on_stream => sub {
        my $stream = shift;
        $stream->configure(
            on_read => sub {
                my ( $self, $buffref, $eof ) = @_;
                return 0 unless $eof;
                my $temp = thaw($$buffref);
                save_data($$temp);
                #print_temp($$temp);
                $$buffref = "";
            },
            on_closed => sub { },
        );
        $loop->add($stream);
    },
    on_resolve_error => sub { print STDERR "Cannot resolve - $_[0]\n"; },
    on_listen_error  => sub { print STDERR "Cannot listen\n"; },
);

$loop->run;

sub print_temp {
    my $temp = shift;
    say Dumper($temp);
}

sub start_listener { }

sub receive_data { }

sub save_data { 
    my $data = shift;
    say Dumper($data);
}

sub draw_graphs { }

