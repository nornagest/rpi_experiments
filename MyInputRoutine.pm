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

package MyInputRoutine;

use Modern::Perl 2013;
use warnings;

use IO::Async::Channel;
use IO::Async::Routine;
use Time::HiRes qw(usleep);

sub create_input_routine($$$) {
    my ($loop, $piface, $handle_input_ref) = @_;

    my $out_ch  = IO::Async::Channel->new;
    my $input_routine = IO::Async::Routine->new(
        channels_out => [ $out_ch ],

        code => sub {
            $piface->init;

            my $last_input = 0;
            while(1) {
                my $input = $piface->read_byte();
                if ($input != $last_input ) {
                    $out_ch->send( { 'input' => $input, 'last_input' => $last_input } );
                    $last_input = $input;
                }
                usleep(10000);
            }
        },

        on_finish => sub {
            say "Input routine exited.";
            $piface->deinit;
        },
    );
    $loop->add( $input_routine );

    $out_ch->configure(
        on_recv => sub {
            my ( $ch, $refout ) = @_;

            if(defined $refout->{'input'} && defined $refout->{'last_input'}) {
                my $input = $refout->{'input'};
                my $last_input =  $refout->{'last_input'};
                $handle_input_ref->($input, $last_input);
            }
        }
    );
}

1;
