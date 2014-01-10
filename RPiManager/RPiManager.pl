#!/usr/bin/perl 
#===============================================================================
#
#         FILE: RPiManager.pl
#
#        USAGE: ./RPiManager.pl  
#
#  DESCRIPTION: Program to manage some stuff on a Raspberry Pi and have fun
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

#===============================================================================
#TODO:
#add fault tolerance
#
#manage notifiers (or just access via $loop)
#
#use Exporter
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
#
#handle button combinations
#===============================================================================

use Modern::Perl 2013;
use warnings;

use Function::Clock;

#use Interface::MyNoPiFace; #dummy for testing locally
use Interface::MyPiFace;

use Notifier::MyInputRoutine;
use Notifier::MyOutputRoutine;
use Notifier::MyTimer;

use IO::Async::Loop;


my $out_ch;
my $last_output;
my $block_output = 0; #don't override output of main

my $piface = MyPiFace->new;
my $clock = Function::Clock->new('output_ref' => \&sub_output);
my $loop = IO::Async::Loop->new;

&create_and_add_notifiers($loop, $piface);
say "Ready...";
$clock->print_state();

$loop->run;

#===============================================================================

sub create_and_add_notifiers($$) {
    my ($loop, $piface) = @_;

    MyInputRoutine::create_input_routine($loop, $piface, \&handle_input);
    $out_ch = MyOutputRoutine::create_output_routine($loop, $piface);
    MyTimer::create_timer_periodic($loop, 0.1, 1, sub { $clock->on_tick() });
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

    #TODO: think about one handler function instead of one per button
    $clock->on_button->[$button]( $clock );
    $clock->print_state();
    blink_once($clock->state, 0.5);

    if    ($button == 0) { 
    } elsif ($button == 1) { 
    } elsif ($button == 2) {
    } elsif ($button == 3) { 
        finish();
    };
}

sub handle_tick() {
}

sub blink_once($$) {
    my ($value, $duration) = @_;

    main_output($value, 1);
    MyTimer::create_timer_countdown($loop, $duration, sub { main_output( 0, 0 ) });
}

sub blink($$) {
    my ($value, $interval) = @_;

    #TODO: Implement
}

sub main_output($$) {
    my ($value, $block) = @_;

    $block_output = $block;
    output($value);
}

sub sub_output($) {
    my $value = shift;

    output($value) unless $block_output;
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

