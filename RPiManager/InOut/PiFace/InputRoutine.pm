#
#===============================================================================
#
#         FILE: MyInputRoutine.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hagen Kuehl
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/09/2014 07:51:22 PM
#     REVISION: ---
#===============================================================================

#TODO: Make this a Notifier
package InOut::PiFace::InputRoutine;

use Modern::Perl 2013;
use Moose;
use Notifier::Routine;
use Time::HiRes qw(sleep);

has 'piface' => ( is => 'rw', required => 1,);
has 'channel' => ( is => 'rw', required => 1,);
has 'loop' => ( is => 'rw', required => 1,);
has 'in_ref' => ( is => 'rw', required => 1,);
has 'routine' => ( is => 'rw',);

sub BUILD {
    my $self = shift;
    $self->routine(
        __create_piface_input_routine(
            $self->piface, 
            $self->channel
        )
    );
    $self->loop->add( $self->routine );
    $self->channel->configure(
        on_recv => sub {
            my ( $ch, $refout ) = @_;
            if(defined $refout->{'input'} && defined $refout->{'last_input'}) {
                my $input = $refout->{'input'};
                my $last_input =  $refout->{'last_input'};
                $self->in_ref->($input, $last_input);
            }
        }
    );
}

sub __create_piface_input_routine {
    my ($piface, $channel) = @_;
    
    my $input_code_ref = sub {
        $piface->init;
        my $last_input = 0;
        while(1) {
            my $input = $piface->read_byte();
            die("Input undefined.") unless defined $input;
            if ($input != $last_input ) {
                $channel->send( { 'input' => $input, 'last_input' => $last_input } );
                $last_input = $input;
            }
            sleep(0.01);
        }
    };
    my $on_finish_ref = sub {
        say "Input routine exited.";
        $piface->deinit;
    };
    return Notifier::Routine::create_input_routine($channel, $input_code_ref, $on_finish_ref);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
