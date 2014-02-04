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

#TODO: Handle input as string
#  add: next/prev adjust volume
#TODO: check for MPD updates and print them
#  may have to use a routine for updates

#add two timers:
# 1: ping every 5s 
# 2: check every second for status and print that / set state

sub BUILD {
    my $self = shift;
    $self->Manager->add( $self );
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
    if(defined $byte) {
        $self->handle_input($byte);
        $self->print_state if $byte > 0 && $byte < 8;
    }
};

sub handle_input {
    my ($self, $byte) = @_;
#Inputs:
# Play/Stop -> 1->0 edge (input 0 if input was 1 before; on 2 or 4 lock auf true)
#   1 -> { __input_state = 1 if __input_state == 0; }
#   0 -> { play/stop if __input_state == 1; __input_state=0 }
#   else -> { __input_state = 7; }
# Vol+ -> 4
# Vol- -> 2
# Next -> 5
# Prev -> 3
    say "MPD: handle_input ", $self->__input_state, " ", $byte;
    $self->state_0($byte) if $self->__input_state == 0;
    $self->state_1($byte) if $self->__input_state == 1;
    $self->state_2($byte) if $self->__input_state == 2;
    $self->state_4($byte) if $self->__input_state == 4;
}

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
    $self->__mpd->ping;
    $self->__mpd->play;
    $self->__state('playing');
}
sub stop {
    my $self = shift;
    say "MPD: stop ", $self->__state;
    $self->__mpd->ping;
    $self->__mpd->stop;
    $self->__state('stopped');
}

sub print_state {
    my $self = shift;
    my $message = Message::Output->new(
        'Source' => $self->Name,
        'Content' => { 'string' => $self->__state },
    );
    $self->Manager->send($message);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
