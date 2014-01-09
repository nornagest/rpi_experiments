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

#TODO:
#add fault tolerance
#
#manage notifiers (or just access via $loop)
#
#rename (GOOD NAME!)
#
#extract PiFace stuff
#extract creation of notifiers
#extract clock part for modularization for different outputs
#
#indicate current output state (show on change for a moment)
#kill subprocess/routine and reset PiFace on exit
#make a state machine for menu (+/-/ok/back via buttons)
#
#other modules:
#temperature
#load
#audio volume
#
#manage programs/services module (indicators via LEDs, start/stop via buttons)
#read/request info from other hosts/programs via sockets 
# (e.g. temperature from creampi)
#write information to DB/file
#
#web frontend (first just output, then control)
#integration with nornagest.org (just transfer info/write info to DB on 
# server/accept requests from server)
#
#use outputs (relais/433MHz)
#
#control/integrate camera module on creampi

use Modern::Perl 2013;
use warnings;

use MyInputRoutine;
use MyOutputRoutine;
use MyTimer;

use IO::Async::Loop;

#use MyNoPiFace; #dummy for testing locally
use MyPiFace;

#0 - seconds
#1 - minutes
#2 - hours
#3 - day
#4 - month
#5 - year
my $state = 0;
#value to mod by for cycling through fiels
my $state_mod = 6;

my $out_ch;
my $last_output;

my $piface = MyPiFace->new;
my $loop = IO::Async::Loop->new;

&create_and_add_notifiers($loop, $piface);
say "Ready...";
$loop->run;

###########################################

sub create_and_add_notifiers($$) {
    my ($loop, $piface) = @_;
    MyInputRoutine::create_input_routine($loop, $piface, \&handle_input);
    $out_ch = MyOutputRoutine::create_output_routine($loop, $piface);
    MyTimer::create_timer_periodic($loop, 0.1, 1, \&handle_tick);
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

#TODO:
#use sub references for reaction to buttons => make dynamic
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

sub handle_tick() {
    my @time = localtime();
    my $time = $time[$state];
    $time++ if $state == 4;      # adjust month representation 
    $time %= 100 if $state == 5; # adjust year representation
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

sub output($) {
    my $value = shift;

    $out_ch->send( \$value ) unless defined $last_output && $value == $last_output;
    $last_output = $value;
}

sub finish {
    $loop->stop;
    &output(0);
    say "Goodbye!";
}

