#
#===============================================================================
#
#         FILE: Client.pm
#
#  DESCRIPTION:
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (),
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 01/25/2014 02:08:09 PM
#     REVISION: ---
#===============================================================================

#TODO: error handling
package Module::Temperature::Client;
use Modern::Perl 2013;
use Moose;
extends 'Module::Temperature';
use curry;
use IO::Async::Stream;
use Message::Output;
use Notifier::Timer;
use Storable qw(thaw);

has '+Name' => ( is => 'ro', isa => 'Str', default => 'Temperature-Client' );
has '+__direction' => ( default => '' );
has '+__type'      => ( default => '' );

has 'Interval' => ( is => 'ro', isa => 'Int', default => 60 );

sub BUILD {
    my $self  = shift;
    my $timer = Notifier::Timer::create_timer_periodic( $self->Interval, 0,
        sub { $self->on_tick() } );
    $self->Manager->add($self);
    $self->Manager->Loop->add($timer);
}

sub on_tick {
    my $self       = shift;
    my $print_temp = $self->curry::print;
    $self->Manager->Loop->connect(
        host     => $self->Host,
        service  => $self->Port,
        socktype => 'stream',

        on_stream => sub {
            my $stream = shift;
            $stream->configure(
                on_read => sub {
                    my ( $self, $buffref, $eof ) = @_;
                    return 0 unless $eof;
                    $print_temp->( thaw($$buffref) );
                    $$buffref = "";
                },
                on_closed => sub { }
            );
            $self->Manager->Loop->add($stream);
        },
        on_resolve_error => sub { die "Cannot resolve - $_[0]\n" },
        on_connect_error => sub { die "Cannot connect\n" },
    );
}

sub print {
    my ( $self, $temp ) = @_;
    my @lines;
    for ( sort keys %{ $temp->{"sensors"} } ) {
        push @lines, $temp->{"time"} . " " . $_ . " " . $temp->{"sensors"}{$_};
    }
    my $message = Message::Output->new(
        'Source'  => $self->Name,
        'Content' => { 'string' => join "\n", @lines },
    );
    $self->Manager->send($message);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

