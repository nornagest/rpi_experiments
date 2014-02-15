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

package Module::Clock;
use Modern::Perl 2013;
use Moose;
extends 'Module';

use Message::Output;
use Notifier::Timer;

has '+Name' => ( is => 'ro', isa => 'Str', default => 'Clock' );
has '+__direction' => ( default => 'Input' );
has '+__type'      => ( default => 'byte' );

has '__state'        => ( is => 'rw', isa => 'Int',     default => 0, );
has '__output'       => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has '__block_output' => ( is => 'rw', isa => 'Bool',    default => 0 );

sub BUILD {
    my $self = shift;
    my $timer = Notifier::Timer::create_timer_periodic( 0.1, 0,
        sub { $self->on_tick() } );
    $self->Manager->add($self);
    $self->Manager->Loop->add($timer);
}

override 'send' => sub {
    my ( $self, $input ) = @_;
    return unless $self->accepts($input);
    my $byte = $input->Content->{byte};
    if ( defined $byte ) {
        $self->next        if $byte & 1;
        $self->prev        if $byte & 2;
        $self->reset       if $byte & 4;
        $self->print_state if $byte > 0 && $byte < 8;
    }
};

my $state_mod = 6;

sub on_tick {
    my $self = shift;
    my @time = localtime();
    my $time = $time[ $self->__state ];
    $time++ if $self->__state == 4;    # adjust month representation
    $time %= 100 if $self->__state == 5;    # adjust year representation

    return
      if $self->__block_output
      || ( defined $self->__output->{byte}
        && $self->__output->{byte} == $time );
    $self->__output->{"byte"}   = $time;
    $self->__output->{"string"} = scalar localtime();
    $self->print;
}

sub next {
    my $self = shift;
    $self->__state( ( $self->__state + 1 ) % $state_mod ) if defined $self;
}

sub prev {
    my $self = shift;
    $self->__state( ( $self->__state - 1 ) % $state_mod ) if defined $self;
}

sub reset {
    my $self = shift;
    $self->__state(0) if defined $self;
}

sub print_state {
    my $self = shift;
    my @states = ( 'Seconds', 'Minutes', 'Hours', 'Day', 'Month', 'Year' );
    $self->__output(
        { "byte" => $self->__state, "string" => $states[ $self->__state ] } );
    $self->print;

    #TODO: Think about moving this to Manager/new output module and find a general solution
    $self->__block_output(1);
    $self->Manager->Loop->add(
        Notifier::Timer::create_timer_countdown(
            0.5, sub { $self->__block_output(0) }
        )
    );
}

sub print {
    my $self    = shift;
    my $message = Message::Output->new(
        'Source'  => $self->Name,
        'Content' => $self->__output,
    );
    $self->Manager->send($message);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
