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
use Carp;
use IO::Async::Function;
use IO::Async::Listener;
use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use YAML qw(thaw);
use RRDTool::OO;
use RRD;
use DataSource;

$| = 1;

my $port = 12345;

my %rrds;
for ( RRD->get_rrds() ) {
    create_rrd($_);
}

my $loop = IO::Async::Loop->new;

my $draw_graphs = IO::Async::Function->new(
    code => sub {
        my ( $start, $end, $name ) = @_;
        for ( values %rrds ) {
            $_->create_graph( $start, $end, $name );
        }
    },
);

$loop->add($draw_graphs);

#$function->call(
#   args => [ 123454321 ],
#)->on_done( sub {
#   my $isprime = shift;
#   print "123454321 " . ( $isprime ? "is" : "is not" ) . " a prime number\n";
#})->on_fail( sub {
#   print STDERR "Cannot determine if it's prime - $_[0]\n";
#})->get;

my $timer = IO::Async::Timer::Periodic->new(
    interval       => 300,
    first_interval => 1,
    on_tick        => sub {
        print "Creating graphs ";
        my $now    = time();
        my $start  = $now - 4 * 3600;
        my $suffix = '00004h';
        $draw_graphs->call( args => [ $start, $now, $suffix ] )->get;

        $start  = $now - 24 * 3600;
        $suffix = '00024h';
        $draw_graphs->call( args => [ $start, $now, $suffix ] )->get;

        $start  = $now - 7 * 24 * 3600;
        $suffix = '00168h';
        $draw_graphs->call( args => [ $start, $now, $suffix ] )->get;

        $start  = $now - 4 * 7 * 24 * 3600;
        $suffix = '00672h';
        $draw_graphs->call( args => [ $start, $now, $suffix ] )->get;

        $start  = $now - 12 * 7 * 24 * 3600;
        $suffix = '02016h';
        $draw_graphs->call( args => [ $start, $now, $suffix ] )->get;

        $start  = $now - 365 * 24 * 3600;
        $suffix = '08760h';
        $draw_graphs->call( args => [ $start, $now, $suffix ] )->get;

        $start  = $now - 5 * 365 * 24 * 3600;
        $suffix = '43800h';
        $draw_graphs->call( args => [ $start, $now, $suffix ] )->get;
        print "done ";
    },
);

$timer->start;
$loop->add($timer);

$loop->listen(
    service  => $port,
    socktype => 'stream',

    on_stream => sub {
        my $stream = shift;
        $stream->configure(
            on_read => sub {
                my ( $self, $buffref, $eof ) = @_;

                my @messages =
                  sort { $$a->{data}->[0]->{time} <=> $$b->{data}->[0]->{time} }
                  grep { is_correct($_) }
                  map {
                    eval { thaw( $_ . "\n" ) }
                  }
                  split "\n\n", $$buffref;

                for (@messages) {
                    $self->__loop->later( 
                        sub { save_data($$_) }
                    );
                }
                $$buffref = "";
            },
            on_closed => sub { },
        );
        $loop->add($stream);
    },
    on_resolve_error => sub { carp "Cannot resolve - $_[0]\n"; },
    on_listen_error  => sub { carp "Cannot listen\n"; },
);

$loop->run;

sub is_correct {
    my $message = shift;

    return ref($message) eq 'REF'
      && defined $$message->{host}
      && defined $$message->{data};
}

sub create_rrd {
    my ( $name, $datasources ) = @_;

    if ( defined $datasources ) {
        $rrds{$name} = RRD->new( name => $name, datasources => $datasources );
    }
    else {
        $rrds{$name} = RRD->new( name => $name );
    }
}

sub save_data {
    my $message = shift;
    my $data    = $message->{'data'};

    my $host = $message->{'host'};
    for ( @{$data} ) {
        my $ds = $_->{'ds'};
        next
          unless defined $ds && defined $ds->{'name'} && defined $ds->{'type'};
        my $rrd_name = $host . '_' . $_->{'ds'}->{'name'};

        my $datasource = DataSource->new(
            name => $ds->{'name'},
            type => $ds->{'type'},
        );
        $datasource->{'description'} = $ds->{'description'};

        create_rrd( $rrd_name, [$datasource] ) unless defined $rrds{$rrd_name};
        print ".";
        carp "Error: $@" unless eval { $rrds{$rrd_name}->update_rrd( [$_] ) };
    }
}

