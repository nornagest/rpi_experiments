#
#===============================================================================
#
#         FILE: MyOutputRoutine.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hagen Kuehl
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/09/2014 07:51:31 PM
#     REVISION: ---
#===============================================================================

package IO::PiFaceOutputRoutine;

use Modern::Perl 2013;
use Moose;
use Notifier::Routine;

has 'piface' => ( is => 'rw', required => 1,);
has 'channel' => ( is => 'rw', required => 1,);
has 'loop' => ( is => 'rw', required => 1,);
has 'routine' => ( is => 'rw',);

sub BUILD {
    my $self = shift;
    $self->routine(
        __create_piface_output_routine(
            $self->piface,
            $self->channel,
        )
    );
    $self->loop->add( $self->routine );
};

sub __create_piface_output_routine {
    my ($piface, $channel) = @_;

    my $output_code_ref = sub {
            $piface->init;
            while(1) {
                my $input = ${$channel->recv};
                $piface->write_byte($input);
            }
    };
    my $on_finish_ref = sub {
            say "Output routine exited.";
            $piface->deinit;
    };

    return Notifier::Routine::create_output_routine($channel, $output_code_ref, $on_finish_ref);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
