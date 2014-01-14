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
#better encapsulation
# => make interaction more sane 
# => less giving CodeRefs to each other
#  => use objects and curry
#
#IN: Type + Value => give to Main
#OUT: register outputs + accepting Types => accept from Main and dispatch
#  types: text, piface/byte, object
#
#Devices: PiFace / GPIO / Sensors
#
#Notifier: encapsulate IO::Async implementation
#
#Modules: implement Functionality 
#
#Main/Reactor: build a state machine for handling stuff
# keep main state
# manage inputs + outputs
# keep track of modules
#
#------
#think about state of modules 
# Clock:
# Part 1: functionality (create timer, on_tick give time to Main for output)
# Part 2: output time (on PiFace), react to buttons and change output accordingly
#think about Childmanager instead of Routine
#------
#change from specific buttons to input value (numbers)
#===============================================================================
#add fault tolerance / error handling
#use Exporter in modules
#
#kill subprocess/routine and reset PiFace on exit
#make a state machine for menu (+/-/ok/back via buttons)
#===============================================================================
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
#run on creampi
# i/o web frontend
# upload to nornagest.org
#===============================================================================

use Modern::Perl 2013;
use warnings;

use Module::Clock;
#WebCam
#Temperature
#Web -> Mojo? Dancer? Listener?

use Device::MyNoPiFace; #dummy for testing locally
#use Device::MyPiFace;

use In::PiFaceInputRoutine;
use Out::PiFaceOutputRoutine;
use Notifier::Timer;

use IO::Async::Loop;


use IO::Async::Channel;
my $in_ch = IO::Async::Channel->new;
my $out_ch = IO::Async::Channel->new;
my $last_output;
#TODO: change this into some kind of semaphore and ideally make it kind of safe
my $block_output = 0; #don't override output of main

my $piface = MyPiFace->new;
my $clock = Module::Clock->new('output_ref' => \&sub_output);
my $loop = IO::Async::Loop->new;

&create_and_add_notifiers($loop, $piface);
say "Ready...";
$clock->print_state();

$loop->run;

#===============================================================================

sub create_and_add_notifiers() {
    my $input_routine = In::PiFaceInputRoutine::create_piface_input_routine($piface, $in_ch);
    my $output_routine = Out::PiFaceOutputRoutine::create_piface_output_routine($piface, $out_ch);
    my $ticker = Notifier::Timer::create_timer_periodic(0.1, 1, sub { $clock->on_tick() });

    $loop->add( $input_routine );
    $loop->add( $output_routine );
    $loop->add( $ticker );

    $in_ch->configure(
        on_recv => sub {
            my ( $ch, $refout ) = @_;

            if(defined $refout->{'input'} && defined $refout->{'last_input'}) {
                my $input = $refout->{'input'};
                my $last_input =  $refout->{'last_input'};
                handle_input($input, $last_input);
            }
        }
    );
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

sub blink_once($$) {
    my ($value, $duration) = @_;

    main_output($value, 1);
    my $countdown = Notifier::Timer::create_timer_countdown($duration, sub { main_output( 0, 0 ) });
    $loop->add( $countdown );
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
    main_output(0, 1);
    say "Goodbye!";
}

