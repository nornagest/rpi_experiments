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

package Module::PiFace;

use Moose;
extends 'Module';

use Modern::Perl 2013;
use warnings;

use IO::Async::Channel;
use Module::PiFace::InputRoutine;
use Module::PiFace::OutputRoutine;
use Message::Input;

use Device::MyNoPiFace; #dummy for testing locally
#use Device::MyPiFace;

has '+Name' => ( is => 'ro', isa => 'Str', default => 'PiFace' );
has '+__direction' => ( default => 'Output' );
has '+__type' => ( default => 'byte' );

has 'MyPiFace' => ( is => 'rw', isa => 'Object' );
has 'In_Channel' => ( is => 'rw', isa => 'Object' );
has 'Out_Channel' => ( is => 'rw', isa => 'Object' );
has 'last_output' => ( is => 'rw', isa => 'Int' );

sub BUILD {
    my $self = shift;
    $self->In_Channel( IO::Async::Channel->new );
    $self->Out_Channel( IO::Async::Channel->new);
    $self->MyPiFace(Device::MyPiFace->new);
    $self->Manager->add( $self );
    $self->create_routines();
}

override 'send' => sub {
    my ($self, $output) = @_;
    return unless $self->accepts($output);
    my $byte = $output->Content->{byte} if defined $output->Content->{byte};
    return if defined $self->last_output && $self->last_output == $byte;
    $self->Out_Channel->send( \$byte );
    $self->last_output($byte);
};

sub handle_input {
    my ($self, $input) = @_;
    my $message = Message::Input->new(
        'Source'  => $self->Name,
        'Content' => { 'byte' => $input },
    );
    $self->Manager->send( $message );
}

sub create_routines {
    my $self = shift;
    my $in_routine = Module::PiFace::InputRoutine->new(
        'piface' => $self->MyPiFace, 
        'channel' => $self->In_Channel, 
        'loop' => $self->Manager->Loop,
        'in_ref' => sub { 
            my $input = shift;
            $self->handle_input($input) 
        },
    );
    my $out_routine = Module::PiFace::OutputRoutine->new(
        'piface' => $self->MyPiFace, 
        'channel' => $self->Out_Channel, 
        'loop' => $self->Manager->Loop,
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


