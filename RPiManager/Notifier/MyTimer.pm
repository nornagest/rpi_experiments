#
#===============================================================================
#
#         FILE: MyTimer.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hagen Kuehl
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/09/2014 11:14:08 PM
#     REVISION: ---
#===============================================================================

package MyTimer;

use Modern::Perl 2013;
use warnings;
 
use IO::Async::Timer::Absolute; 
use IO::Async::Timer::Countdown; 
use IO::Async::Timer::Periodic; 

sub create_timer_periodic($$$$) {
    my ($loop, $interval, $first_interval, $on_tick_ref) = @_;

    my $timer = IO::Async::Timer::Periodic->new(
        interval => $interval,
        first_interval => $first_interval,
        on_tick => $on_tick_ref,
    );
    $timer->start;
    $loop->add( $timer );
}

sub create_timer_countdown($$) {
    my ($loop, $delay, $on_expire_ref) = @_;

    my $timer = IO::Async::Timer::Countdown->new(
        delay => $delay,
        on_expire => $on_expire_ref,
    );
    $timer->start;
    $loop->add( $timer );
}

sub create_timer_absolute($$) {
    my ($loop, $time, $on_expire_ref) = @_;

    my $timer = IO::Async::Timer::Absolute->new(
        time => $time,
        on_expire => $on_expire_ref,
    );
    $timer->start;
    $loop->add( $timer );
}

1;
