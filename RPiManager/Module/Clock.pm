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

my $state_mod = 6;

has 'state' => ( is => 'rw', isa => 'Int', default => 0,);
has 'on_button' => ( is => 'ro', isa => 'ArrayRef', 
    default => sub { [ \&next, \&prev, \&reset, sub {} ] },
);
has 'output_ref' => ( is => 'ro', isa => 'CodeRef', default => sub {});

has 'output' => ( is => 'rw', isa => 'HashRef' );

sub on_tick {
    my $self = shift;

    my @time = localtime();
    my $time = $time[$self->state];
    $time++ if $self->state == 4;      # adjust month representation 
    $time %= 100 if $self->state == 5; # adjust year representation
    $self->output_ref->($time);

    $self->output( { "byte" => $time, "string" => scalar localtime() } );
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

#TODO: Remove this or come up with right way to output
sub print_state {
    my $self = shift;
    my $state = $self->state;
    my @states = ( 'Seconds', 'Minutes', 'Hours', 'Day', 'Month', 'Year' );
    say $states[$state];
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
