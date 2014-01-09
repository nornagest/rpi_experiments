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

#TODO:
#move MyPiFace::OutputRoutine
package MyOutputRoutine;

use Modern::Perl 2013;
use warnings;

use IO::Async::Channel;
use IO::Async::Routine;

sub create_output_routine($$) {
    my ($loop, $piface) = @_;

    my $in_ch = IO::Async::Channel->new;
    my $output_routine = IO::Async::Routine->new(
        channels_in  => [ $in_ch ],

        code => sub {
            $piface->init;

            while(1) {
                my $input = ${$in_ch->recv};
                $piface->write_byte($input);
            }
        },

        on_finish => sub {
            say "Output routine exited.";
            $piface->deinit;
        },
    );
    $loop->add( $output_routine );
    return $in_ch;
}

1;
