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

package Out::PiFaceOutputRoutine;

use Modern::Perl 2013;
use warnings;

use Notifier::Routine;

sub create_piface_output_routine {
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

1;
