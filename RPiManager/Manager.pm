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

package Manager;
use Modern::Perl 2013;
use Moose;
use Module;
use Message;

has 'Loop' => ( is => 'ro', isa => 'Object', required => 1 );
has 'Modules' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

has '__sinks' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has '__state' => ( is => 'rw', isa => 'Int', default => 0 );
has '__mod_active' => ( is => 'rw', isa => 'Bool', default => 0 );
has '__input' => ( is => 'rw', isa => 'Int', default => 0 );
has '__multi_in' => ( is => 'rw', isa => 'Bool', default => 0 );

sub add {
    my ($self, $module) = @_;
    my $guid = $module->GUID;
    $self->Modules->{$guid} = $module unless defined $self->Modules->{$guid};
};

sub remove_module {
    my ($self, $module) = @_;
    my $guid = $module->GUID;
    $self->Modules->{$guid} = undef;
};

sub send {
    my ($self, $message) = @_;
    $self->dispatch_message($message);
}

sub dispatch_message {
    my ($self, $message) = @_;
    my $direction = $message->Direction;
    my $source = $message->Source;
    my $content = $message->Content;

    if ( $direction eq 'Input' && defined $content->{byte} ) {
        my @sinks = grep $self->Modules->{$_}->accepts($message), keys $self->Modules;
        $self->__sinks(\@sinks);
        $self->handle_input($content->{byte}, $message);
    } else {
        map $_->send($message), grep $_->accepts($message),values $self->Modules;
    }
};

sub handle_input {
    my ($self, $byte, $message) = @_;
    my $input = $self->__input;
    return if $byte == $input;

    if ( $byte < $input ) {
        $self->send_input( $input - $byte, $message ) unless $self->__multi_in;
        $self->__multi_in( $byte > 0 );
    }

    $self->__input($byte);
}

sub send_input {
    my ($self, $byte, $message) = @_;

    if ( $self->__mod_active ) {
        $self->state_module($byte, $message);
    } else {
        $self->state_main($byte, $message);
    }
}

sub state_main {
    my ($self, $byte, $message) = @_;

    if ($byte == 1) {
        $self->__mod_active(1);
    } elsif ($byte == 8) {
        $self->finish;
    } else {
        my $state = $self->__state;
        $state++ if $byte == 4;
        $state-- if $byte == 2;
        $state %= scalar @{$self->__sinks};
        $self->__state($state);
    }
    $self->print_state($byte);
}

sub state_module {
    my ($self, $byte, $message) = @_;

    if ( $byte == 8 ) {
        $self->__mod_active(0);
    } else {
        my $state = $self->__state;
        my $sink = $self->__sinks->[$state];
        $message->Content->{byte} = $byte; #TODO: This must probably be done in send_input or handle_input
        $self->Modules->{$sink}->send($message);
    }
    $self->print_state($byte);
}

sub print_state {
    my ($self, $byte) = @_;

    #TODO: Add LED display of module
    my $state = $self->__state;
    my $sink = $self->__sinks->[$state];
    if($self->__mod_active) {
        say "Module: ", $self->Modules->{$sink}->Name;
    } else {
        say "Main ", $self->Modules->{$sink}->Name;
    }
}

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
