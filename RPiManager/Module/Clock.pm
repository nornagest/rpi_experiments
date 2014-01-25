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

use Message::Output;
use Notifier::Timer;

has '+Name' => ( is => 'ro', isa => 'Str', default => 'Clock' );
has '+__direction' => ( default => 'Input' );
has '+__type' => ( default => 'byte' );

has 'state' => ( is => 'rw', isa => 'Int', default => 0,);
has 'output' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has 'block_output' => ( is => 'rw', isa => 'Bool', default => 0 );


sub BUILD {
    my $self = shift;
    my $timer = Notifier::Timer::create_timer_periodic(0.1, 0, sub { $self->on_tick() });
    $self->Manager->add( $self );
    $self->Manager->Loop->add( $timer );
}

override 'send' => sub {
    my ($self, $input) = @_;
    return unless $self->accepts($input);
    my $byte = $input->Content->{byte} if defined $input->Content->{byte};
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

    return if $self->block_output || (defined $self->output->{byte} 
        && $self->output->{byte} == $time);
    $self->output( { "byte" => $time, "string" => scalar localtime() } );
    $self->print;
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
    my @states = ( 'Seconds', 'Minutes', 'Hours', 'Day', 'Month', 'Year' );
    $self->output( 
        { "byte" => $self->state, "string" => $states[$self->state] } );
    $self->print;

    $self->block_output(1);
    $self->Manager->Loop->add( Notifier::Timer::create_timer_countdown( 
            0.5, sub { $self->block_output(0) } ) );
}

sub print {
    my $self = shift;
    my $message = Message::Output->new(
        'Source'  => $self->Name,
        'Content' => $self->output,
    );
    $self->Manager->send($message);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
