#
#===============================================================================
#
#         FILE: Routine.pm
#
#  DESCRIPTION:
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (),
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 01/11/2014 12:04:50 PM
#     REVISION: ---
#===============================================================================

#TODO: make this a class
package Notifier::Routine;
use Modern::Perl 2013;
use IO::Async::Routine;

sub create_routine {
    my ( $input_channel, $output_channel, $code_ref, $on_finish_ref, ) = @_;

    my $routine = IO::Async::Routine->new(
        channels_in  => [$input_channel],
        channels_out => [$output_channel],
        code         => $code_ref,
        on_finish    => $on_finish_ref,
    );
    return $routine;
}

sub create_input_routine {
    my ( $output_channel, $code_ref, $on_finish_ref, ) = @_;

    my $input_routine = IO::Async::Routine->new(
        channels_out => [$output_channel],
        code         => $code_ref,
        on_finish    => $on_finish_ref,
    );
    return $input_routine;
}

sub create_output_routine {
    my ( $input_channel, $code_ref, $on_finish_ref, ) = @_;

    my $output_routine = IO::Async::Routine->new(
        channels_in => [$input_channel],
        code        => $code_ref,
        on_finish   => $on_finish_ref,
    );
    return $output_routine;
}

1;
