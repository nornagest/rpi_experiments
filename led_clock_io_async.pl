#!/usr/bin/perl 
#===============================================================================
#
#         FILE: led_clock_io_async.pl
#
#        USAGE: ./led_clock_io_async.pl  
#
#  DESCRIPTION: Show time in binary format with PiFace LEDs, switch between
#               hour, minute and second display on button press
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hagen Kuehl
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/08/2014 10:59:45 PM
#     REVISION: ---
#===============================================================================

#other ideas:
#display:
# temperature
# load
# output volume
#
#change:
# audio volume

#TODO:
#extract PiFace stuff
#extract creation of notifiers
#indicate current output state (show on change for a moment)
#kill subprocess/routine and reset PiFace on exit

use Modern::Perl 2013;
use warnings;

use MyOutputRoutine;
use MyInputRoutine;

use IO::Async::Loop;
use IO::Async::Timer::Periodic; 
use IO::Async::Timer::Countdown; 

#use MyNoPiFace; #dummy for testing locally
use MyPiFace;

my $piface = MyPiFace->new;

#value to mod by for cycling through fiels
my $state_mod = 6;

#0 - seconds
#1 - minutes
#2 - hours
#3 - day
#4 - month
#5 - year
my $state = 0;

my $out_ch;
my $loop = IO::Async::Loop->new;

&create_and_add_notifiers($loop, $piface);
say "Ready...";
$loop->run;

###########################################

sub create_and_add_notifiers($$) {
    my ($loop, $piface) = @_;
    MyInputRoutine::create_input_routine($loop, $piface, \&handle_input);
    $out_ch = MyOutputRoutine::create_output_routine($loop, $piface);
    create_timer($loop);
}

sub create_timer($) {
    my $loop = shift;

    my $timer = IO::Async::Timer::Periodic->new(
        interval => 0.1,
        first_interval => 1,
        on_tick => sub { handle_tick(); },
    );
    $timer->start;
    $loop->add( $timer );
}

sub handle_input($$) {
    my ($input, $last_input) = @_;
    my @buttons = (0,0,0,0);
    for my $i (0..3) {
        $buttons[$i] = ($input & (1<<$i)) >> $i;
        if ( $buttons[$i] == 1  && ($last_input & (1 << $i)) == 0 ) {
            handle_button($i);
        }
    }
}

sub handle_button($) {
    my $button = shift;

    if    ($button == 0) { 
        $state = ($state + 1) % $state_mod;
    } elsif ($button == 1) { 
        $state = ($state - 1) % $state_mod;
    } elsif ($button == 2) {
        $state = 0;
    } elsif ($button == 3) { 
        finish();
    };
}

#react on timer interrupt
sub handle_tick() {
    #send part of time instead
    my @time = localtime();
    my $time = $time[$state];
    $time++ if $state == 4;      # adjust month representation 
    $time %= 100 if $state == 5; # adjust year representation
#say "Index: $state Output: $time";
    output($time);
}

sub blink_once($$) {
    my ($value, $duration) = @_;

    #TODO: Implement
}

sub blink($$) {
    my ($value, $interval) = @_;

    #TODO: Implement
}

my $last_output;
sub output($) {
    my $value = shift;

    $out_ch->send( \$value ) unless defined $last_output && $value == $last_output;
    $last_output = $value;
}

sub finish {
    $loop->stop;
    say "Goodbye!";
}

