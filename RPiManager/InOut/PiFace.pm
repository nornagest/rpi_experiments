#
#===============================================================================
#
#         FILE: PiFace.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/23/2014 07:57:01 PM
#     REVISION: ---
#===============================================================================

package InOut::PiFace;

use Moose;
extends 'InOut';

use Modern::Perl 2013;
use warnings;
 
use InOut::PiFace::InputRoutine;
use InOut::PiFace::OutputRoutine;
use IO::Async::Channel;

use Device::MyNoPiFace; #dummy for testing locally
#use Device::MyPiFace;
my $piface_class = 'Device::MyNoPiFace';

has '+Name' => ( is => 'ro', isa => 'Str', default => 'PiFace' );
has '+Type' => ( is => 'ro', isa => 'Str', default => 'byte' );

has 'MyPiFace' => ( is => 'rw', isa => 'Object' );
has 'In_Channel' => ( is => 'rw', isa => 'Object' );
has 'Out_Channel' => ( is => 'rw', isa => 'Object' );

sub BUILD {
    my $self = shift;
    $self->In_Channel( IO::Async::Channel->new );
    $self->Out_Channel( IO::Async::Channel->new);
    $self->MyPiFace($piface_class->new);

    $self->create_routines();
}

sub write {
    my ($self, $output) = @_;
    $self->Out_Channel->send( $output );
};

sub handle_input {
    my ($self, $input, $last_input) = @_;
    say "PiFace handle_input";
    $self->Manager->handle_input($self->Name, $input, $last_input);
}

sub create_routines {
    my $self = shift;
    my $input_routine = InOut::PiFace::InputRoutine->new(
        'piface' => $self->MyPiFace, 
        'channel' => $self->In_Channel, 
        'loop' => $self->Manager->Loop,
        'in_ref' => sub { 
            my ($input, $last_input) = @_;
            say "InputRoutine in_ref";
            $self->handle_input($input, $last_input) 
        },
    );
    my $output_routine = InOut::PiFace::OutputRoutine->new(
        'piface' => $self->MyPiFace, 
        'channel' => $self->Out_Channel, 
        'loop' => $self->Manager->Loop,
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


