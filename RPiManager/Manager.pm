#
#===============================================================================
#
#         FILE: OutputManager.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/13/2014 08:12:21 PM
#     REVISION: ---
#===============================================================================

#TODO:
#Cleanup unneeded methods
#Implement needed methods
package Manager;

use Moose;

use Module;
use InOut;

use Modern::Perl 2013;
use strict;
use warnings;

has 'Loop' => ( is => 'ro', isa => 'Object', required => 1 );
has 'Modules' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has 'InOuts' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

sub add_module {
    my ($self, $module) = @_;
    my $guid = $module->GUID;

    $self->Modules->{$guid} = $module unless defined $self->Modules->{$guid};
};
sub remove_module {};
sub activate_module {};
sub deactivate_module {};

sub add_inout {
    my ($self, $inout) = @_;
    my $guid = $inout->GUID;

    $self->InOuts->{$guid} = $inout unless defined $self->InOuts->{$guid};
};
sub remove_inout {};
sub activate_inout {};
sub deactivate_inout {};

sub handle_input {
    my ($self, $inout, $input) = @_;
    if($input->{byte} == 8) {
        $self->finish;
    }
    for my $module (values $self->Modules) {
        for my $type (keys %$input) {
            $module->write($input) 
            if $module->Type eq $type && $module->Active;
        }
    }
};
sub handle_output {
    my ($self, $module, $output) = @_;
    for my $inout (values $self->InOuts) {
        for my $type (keys %$output) {
            $inout->write($output) 
            if $inout->Type eq $type && $inout->Active;
        }
    }
};
sub dispatch_input {};
sub dispatch_outputs {};

sub finish {
    my $self = shift;
    $self->Loop->stop;

    #TODO: This is NOT nice
    #compare this with the idiomatic solution and rethink system design
    #use $routine->kill when it arrives
    for (values $self->InOuts) {
        if ( $_->Name eq 'PiFace' ) {
            #send SIGTERM to children to make sure they go away.
            $_->In_Routine->routine->{process}->kill(15);
            $_->Out_Routine->routine->{process}->kill(15);
        }
    }
    #a more idiomatic and general way
    #$_->kill(15) for grep $_->isa('IO::Async::Process'), $self->Loop->notifiers;
    say "Goodbye!";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
