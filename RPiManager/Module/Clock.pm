#
#===============================================================================
#
#         FILE: Clock.pm
#
#  DESCRIPTION: Show time in binary format with PiFace LEDs, switch between
#               hour, minute and second display on button press
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hagen Kuehl
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/10/2014 06:14:09 PM
#     REVISION: ---
#===============================================================================

#TODO: Remove old way of output
package Module::Clock;

use Moose;
extends 'Module';

use Modern::Perl 2013;
use warnings;

has '+Name' => ( is => 'ro', isa => 'Str', default => 'Clock' );
has '+Type' => ( is => 'ro', isa => 'Str', default => 'byte' );
has 'state' => ( is => 'rw', isa => 'Int', default => 0,);
has 'output' => ( is => 'rw', isa => 'HashRef' );

override 'write' => sub {
    my ($self, $input) = @_;
    my $byte = $input->{byte} if defined $input->{byte};
    if(defined $byte) {
        $self->next if $byte & 1;
        $self->prev if $byte & 2;
        $self->reset if $byte & 4;
        $self->print_state if $byte > 0 && $byte < 8;
    }
};

my $state_mod = 6;

sub on_tick {
    my $self = shift;

    my @time = localtime();
    my $time = $time[$self->state];
    $time++ if $self->state == 4;      # adjust month representation 
    $time %= 100 if $self->state == 5; # adjust year representation

    $self->output( { "byte" => $time, "string" => scalar localtime() } );
    $self->print;
}

#TODO: Handle byte input from InputManager
sub next {
    my $self = shift;
    $self->state( ($self->state + 1) % $state_mod) if defined $self;
}
sub prev {
    my $self = shift;
    $self->state( ($self->state - 1) % $state_mod) if defined $self;
}
sub reset {
    my $self = shift;
    $self->state( 0 ) if defined $self;
}

sub print_state {
    my $self = shift;
    my @states = ( 'Seconds', 'Minutes', 'Hours', 'Day', 'Month', 'Year' );
    
    $self->output( 
        { "byte" => $self->state, "string" => $states[$self->state] } );
    #say $states[$self->state];
    $self->print;
}

sub print {
    my $self = shift;

    $self->Manager->handle_output( $self->Name, $self->output );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
