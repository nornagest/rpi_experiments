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
use RRD;
use DataSource;

#TODO: include in RPi.pl
#TODO: timings per datasource
#TODO: web frontend

my $port = 12346;

my %rrds;
for(RRD->get_rrds()){
    create_rrd($_);
}

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
                my $message = thaw($$buffref);
                save_data($$message);
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

sub create_rrd {
    my ($name, $datasources) = @_;

    if(defined $datasources) {
        $rrds{$name} = RRD->new(name => $name, datasources => $datasources);
    } else {
        $rrds{$name} = RRD->new(name => $name);
    }
}

sub save_data { 
    my $message = shift;
    my $data = $message->{'data'};

    my $host = $message->{'host'};
    for(@{$data}) {
        my $rrd_name = $host . '_' . $_->{'ds'}->{'name'};

        my $datasource = DataSource->new(
            name => $_->{'ds'}->{'name'},
            type => $_->{'ds'}->{'type'},
        );
        $datasource->{'description'} = $_->{'ds'}->{'description'};
            
        create_rrd($rrd_name, [$datasource]) unless defined $rrds{$rrd_name};
        $rrds{$rrd_name}->update_rrd([$_]);
    }
}

sub draw_graphs {
    for(values %rrds) {
        $_->create_graph();
    }
}

