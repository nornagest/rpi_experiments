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
#implement Input and Output managers
#Make used modules configurable -> config file
#better encapsulation
# => Notifier::Listener
# => hide reading temperature over network somehow
#
# => make interaction more sane 
# => less giving CodeRefs to each other
#  => use objects and curry
#
#IN: Type + Value => give to Main
#OUT: register outputs + accepting Types => accept from Main and dispatch
#  types: text, piface/byte, object
#
#------
#Output idea:
# have module create output hash (on request or tick/interrupt)
# (rpi => $number, console => $string OR byte => $number, string => $string)
# OutputManager pulls hashes from modules it knows/are activated and sends it
#   to submodules for different types/devices)
#TODO: think about additional output, like state!
#------
#
#Devices: PiFace / GPIO / Sensors
#Notifier: encapsulate IO::Async implementation
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
#kill subprocess/routine on exit
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
#Web -> Mojo? Dancer? Listener? HTTP::Server?

use Device::MyNoPiFace; #dummy for testing locally
#use Device::MyPiFace;

use IO::OutputManager;

use IO::PiFaceInputRoutine;
use IO::PiFaceOutputRoutine;

use Notifier::Timer;
use IO::Async::Loop;
use IO::Async::Stream;
use IO::Async::Channel;
use Storable qw(thaw);
my $in_ch = IO::Async::Channel->new;
my $out_ch = IO::Async::Channel->new;
my $last_output;
#TODO: change this into some kind of semaphore and ideally make it kind of safe
#think about multiple button presses -> $block_output++
#remeber last timer and replace or queue new timer
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
    my $input_routine = IO::PiFaceInputRoutine->new(
        'piface' => $piface, 
        'channel' => $in_ch, 
        'loop' => $loop,
        'in_ref' => \&handle_input,
    );
    my $output_routine = IO::PiFaceOutputRoutine->new(
        'piface' => $piface, 
        'channel' => $out_ch, 
        'loop' => $loop,
    );

    my $ticker = Notifier::Timer::create_timer_periodic(0.1, 0, sub { $clock->on_tick() });
    $loop->add( $ticker );
    my $temp_ticker = Notifier::Timer::create_timer_periodic( 60, 0, sub { on_tick() } );
    $loop->add( $temp_ticker );
}

#TODO: Move this to Notifier and Module
sub on_tick {
    $loop->connect(
        host     => "creampi",
        service  => 12345,
        socktype => 'stream',

        on_stream => sub {
            my $stream = shift;
            $stream->configure(
                on_read => sub {
                    my ( $self, $buffref, $eof ) = @_;
                    return 0 unless $eof;
                    print_temp( thaw($$buffref) );
                    $$buffref = "";
                },
                on_closed => sub {
                    #say "Connection closed.";
                }
            );
            $loop->add( $stream );
        },

        on_resolve_error => sub { die "Cannot resolve - $_[0]\n" },
        on_connect_error => sub { die "Cannot connect\n" },
    );
}

sub print_temp {
    my $temp = shift;
    say $temp->{"time"};
    for(sort keys %{$temp->{"sensors"}}) {
        print $_, " => ", $temp->{"sensors"}{$_}, "\n";
    }

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
    #let OutputManager decide which Module methods to call
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

#TODO: Try to use Future
sub blink_once($$) {
    my ($value, $duration) = @_;
    main_output($value, 1);
    my $countdown = Notifier::Timer::create_timer_countdown($duration, 
        sub { main_output( 0, 0 ) });
    $loop->add( $countdown );
}

sub blink($$) {
    my ($value, $interval) = @_;
    my $ticker = Notifier::Timer::create_timer_periodic($interval, 0, 
        sub {}); #TODO: implement and make this a Module
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

