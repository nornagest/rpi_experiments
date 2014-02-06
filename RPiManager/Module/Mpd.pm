#
#===============================================================================
#
#         FILE: Mpd.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/29/2014 08:47:30 PM
#     REVISION: ---
#===============================================================================

package Module::Mpd;

use Modern::Perl 2013;
use Moose;
extends 'Module';

use Message::Output;
use Net::MPD;
use Notifier::Timer;

has '+Name' => ( is => 'ro', isa => 'Str', default => 'MPD' );
has '+__direction' => ( default => 'Input' );
has '+__type' => ( default => 'byte' );

has 'Host' => ( is => 'rw', isa => 'Str', default => 'localhost' );
has 'Port' => ( is => 'rw', isa => 'Int', default => 6600 );
has 'Password' => ( is => 'rw', isa => 'Str', default => '' );

has '__mpd' => ( is => 'rw', isa => 'Net::MPD' );
#TODO: define enum or get a clear idea
has '__state' => ( is => 'rw', isa => 'Str', default => '' );
has '__input_state' => ( is => 'rw', isa => 'Int', default => 0 );
has 'song' => ( is => 'rw', isa => 'Str', default => '' );

#TODO: Handle input as string
#  add: next/prev and adjust volume
#TODO: set __state depending on real state of MPD in sub ping()
#  may have to use a routine for updates

sub BUILD {
    my $self = shift;
    my $timer = Notifier::Timer::create_timer_periodic(1, 1, sub { $self->ping });
    $self->Manager->add( $self );
    $self->Manager->Loop->add( $timer );
    $self->connect;
}

sub connect {
    my $self = shift;
    my $connect_string = $self->Password . '@' . $self->Host . ':' . $self->Port;
    $self->__mpd( Net::MPD->connect($connect_string) );
}

override 'send' => sub {
    my ($self, $input) = @_;
    return unless $self->accepts($input);
    my $byte = $input->Content->{byte} if defined $input->Content->{byte};
    $self->handle_input($byte) if defined $byte;
};

sub ping {
    my $self = shift;
    $self->__mpd->ping;

    my $status = $self->__mpd->update_status;
    my $state = $status->{"state"};
    my $song = $self->__mpd->current_song;
    my $name = $song->{"Name"};

    if( $name ne $self->song || $state ne $self->__state) {
        $self->song($name);
        $self->__state($state);
        $self->print_state;
    }
}

sub handle_input {
    my ($self, $byte) = @_;

    if( $byte == 1) {
        if( $self->__state eq 'play' ) {
            $self->stop;
        } else {
            $self->play;
        }
    }
}

sub play {
    my $self = shift;
    return if $self->__state eq 'play';
    $self->__mpd->play;
}
sub stop {
    my $self = shift;
    $self->__mpd->stop;
}

sub print_state {
    my $self = shift;
    my $output = $self->__state . ' Song: ' . $self->song;
    my $message = Message::Output->new(
        'Source' => $self->Name,
        'Content' => { 'string' => $output },
    );
    $self->Manager->send($message);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
