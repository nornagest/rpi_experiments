#
#===============================================================================
#
#         FILE: Clock.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/10/2014 06:14:09 PM
#     REVISION: ---
#===============================================================================

package Function::Clock;

use Moose;

use Modern::Perl 2013;
use warnings;

my $state_mod = 6;

has 'state' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

has 'on_button' => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [ \&next, \&prev, \&reset, sub {} ] },
);

has 'output_ref' => (
    is => 'ro',
    isa => 'CodeRef',
    default => sub {},
);

sub on_tick {
    my $self = shift;

    my @time = localtime();
    my $time = $time[$self->state];
    $time++ if $self->state == 4;      # adjust month representation 
    $time %= 100 if $self->state == 5; # adjust year representation
    $self->output_ref->($time);
}

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
    my $state = $self->state;
    my @states = ( 'Seconds', 'Minutes', 'Hours', 'Day', 'Month', 'Year' );
    say $states[$state];
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
