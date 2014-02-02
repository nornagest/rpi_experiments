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

#TODO: Handle input as string
#  add: next/prev adjust volume
#TODO: check for MPD updates and print them
#  may have to use a routine for updates
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
        $self->play if $byte & 1;
        $self->stop if $byte & 2;
        #$self->reset if $byte & 4;
        $self->print_state if $byte > 0 && $byte < 8;
    }
};

sub play {
    my $self = shift;
    return if $self->__state eq 'playing';
    $self->__mpd->ping;
    $self->__mpd->play;
    $self->__state('playing');
}
sub stop {
    my $self = shift;
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
