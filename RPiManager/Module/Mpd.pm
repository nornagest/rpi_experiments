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
#  add: next/prev adjust volume
#TODO: check for MPD updates and print them
#  may have to use a routine for updates

#add two timers:
# 1: ping every 5s 
# 2: check every second for status and print that / set state

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
    #my $status = $self->__mpd->update_status;
    my $song = $self->__mpd->current_song;
    my $name = $song->{"Name"};
    if( $name ne $self->song) {
        $self->song($name);
        $self->print_state;
    }
}

sub handle_input {
    my ($self, $byte) = @_;

    if( $byte == 1) {
        if( $self->__state eq 'playing' ) {
            $self->stop;
        } else {
            $self->play;
        }
        #$self->__input_state(0);
    }
    return;

    #shut off state machine for now
    $self->state_0($byte) if $self->__input_state == 0;
    $self->state_1($byte) if $self->__input_state == 1;
    $self->state_2($byte) if $self->__input_state == 2;
    $self->state_4($byte) if $self->__input_state == 4;
}

#TODO: make state machine a role, Manager too
sub state_0 {
    my ($self, $byte) = @_;
    say "MPD: state_0 ", $self->__input_state, " ", $byte;
    $self->__input_state(1) if $byte == 1;
    $self->__input_state(2) if $byte == 2;
    $self->__input_state(4) if $byte == 4;
}

sub state_1 {
    my ($self, $byte) = @_;
    say "MPD: state_1 ", $self->__input_state, " ", $byte;
    if( $byte == 0) {
        if( $self->__state eq 'playing' ) {
            $self->stop;
        } else {
            $self->play;
        }
        $self->__input_state(0);
    }
}

sub state_2 {
    my ($self, $byte) = @_;
    say "MPD: state_2 ", $self->__input_state, " ", $byte;
    if( $byte == 0 ) {
        $self->__input_state(0);
    }
}

sub state_4 {
    my ($self, $byte) = @_;
    say "MPD: state_4 ", $self->__input_state, " ", $byte;
    if( $byte == 0 ) {
        $self->__input_state(0);
    }
}

sub play {
    my $self = shift;
    say "MPD: play ", $self->__state;
    return if $self->__state eq 'playing';
    $self->__mpd->play;
    $self->__state('playing');
    $self->print_state;
}
sub stop {
    my $self = shift;
    say "MPD: stop ", $self->__state;
    $self->__mpd->stop;
    $self->__state('stopped');
    $self->print_state;
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
