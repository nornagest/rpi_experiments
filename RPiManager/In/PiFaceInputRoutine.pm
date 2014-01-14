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

package In::PiFaceInputRoutine;

use Modern::Perl 2013;
use warnings;

use Notifier::Routine;
use Time::HiRes qw(usleep);

#TODO: 
#make this a class
#
#init -> Initialization
#recv -> get Input (?)
#add  -> register callback

sub create_piface_input_routine {
    my ($piface, $channel) = @_;
    
    my $input_code_ref = sub {
        $piface->init;

        my $last_input = 0;
        while(1) {
            my $input = $piface->read_byte();
            if ($input != $last_input ) {
                $channel->send( { 'input' => $input, 'last_input' => $last_input } );
                $last_input = $input;
            }
            usleep(10000);
        }
    };
    my $on_finish_ref = sub {
        say "Input routine exited.";
        $piface->deinit;
    };
    return Notifier::Routine::create_input_routine($channel, $input_code_ref, $on_finish_ref);
}

#TODO: configuration of channel
#    $in_ch->configure(
#        on_recv => sub {
#            my ( $ch, $refout ) = @_;
#
#            if(defined $refout->{'input'} && defined $refout->{'last_input'}) {
#                my $input = $refout->{'input'};
#                my $last_input =  $refout->{'last_input'};
#                handle_input($input, $last_input);
#            }
#        }
#    );

1;
