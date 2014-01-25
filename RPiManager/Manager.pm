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
#Implement other methods
package Manager;
use Modern::Perl 2013;
use Moose;
use Module;
use Message;

has 'Loop' => ( is => 'ro', isa => 'Object', required => 1 );
has 'Modules' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

sub add {
    my ($self, $module) = @_;
    my $guid = $module->GUID;
    $self->Modules->{$guid} = $module unless defined $self->Modules->{$guid};
};

sub remove_module {};
sub activate_module {};
sub deactivate_module {};

sub send {
    my ($self, $message) = @_;
    my $direction = $message->Direction;
    my $source = $message->Source;
    my $content = $message->Content;
    $self->finish if $direction eq 'Input' && defined $content->{byte} 
        && $content->{byte} == 8;
    $self->dispatch_message($message);
}

sub dispatch_message {
    my ($self, $message) = @_;
    map $_->send($message), grep $_->accepts($message),values $self->Modules;
};

sub finish {
    my $self = shift;
    $self->Loop->stop;
    #Make sure all processes exit
    $_->kill(15) for grep $_->isa('IO::Async::Process'), $self->Loop->notifiers;
    say "Goodbye!";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
