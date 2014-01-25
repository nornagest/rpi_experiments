#!/usr/bin/perl 

use Modern::Perl 2013;
use Storable qw(thaw);
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

$loop->connect(
    host     => "localhost",
    service  => 12345,
    socktype => 'stream',

    on_stream => sub {
        my $stream = shift;
        $stream->configure(
            on_read => sub {
                my ( $self, $buffref, $eof ) = @_;
                return 0 unless $eof;
                print_temp( thaw($$buffref) );
                $$buffref = "";
            },
            on_closed => sub {
                $loop->stop;
            }
        );
        $loop->add( $stream );
    },

    on_resolve_error => sub { die "Cannot resolve - $_[0]\n" },
    on_connect_error => sub { die "Cannot connect\n" },
);

$loop->run;

sub print_temp {
    my $temp = shift;
    say "Content-type: text/plain\n";
    say $temp->{"time"};
    for(sort keys %{$temp->{"sensors"}}) {
        print $_, " => ", $temp->{"sensors"}{$_}, "\n";
    }

}

