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
#Web -> Mojo? Dancer? Listener?

#use Device::MyNoPiFace; #dummy for testing locally
use Device::MyPiFace;

use In::PiFaceInputRoutine;
use Out::PiFaceOutputRoutine;
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
#my $clock = Module::Clock->new('output_ref' => \&sub_output);
my $clock = Module::Clock->new('output_ref' => sub {});
my $loop = IO::Async::Loop->new;

&create_and_add_notifiers($loop, $piface);
say "Ready...";
$clock->print_state();

$loop->run;

#===============================================================================

sub create_and_add_notifiers() {
    my $input_routine = In::PiFaceInputRoutine->new(
        'piface' => $piface, 
        'channel' => $in_ch, 
        'loop' => $loop,
        'in_ref' => \&handle_input,
    );
    my $output_routine = Out::PiFaceOutputRoutine->new(
        'piface' => $piface, 
        'channel' => $out_ch, 
        'loop' => $loop,
    );

    my $ticker = Notifier::Timer::create_timer_periodic(0.1, 0, sub { $clock->on_tick() });
    $loop->add( $ticker );
    my $temp_ticker = Notifier::Timer::create_timer_periodic(10, 0, sub { on_tick() });
    $loop->add( $temp_ticker );
}

sub on_tick {
    $loop->connect(
        host     => "creampi",
        service  => 12345,
        socktype => 'stream',

        on_stream => sub {
            my $stream = shift;
            print "Connected.\n";
            $stream->configure(
                on_read => sub {
                    my ( $self, $buffref, $eof ) = @_;
                    #print thaw($buffref);
                    print_temp( thaw($$buffref) );
                    $$buffref = "";
                    return 0;
                },
                on_closed => sub {
                    print "Closed.\n";
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

    for(keys %{$temp}) {
        print $_, " => ", $temp->{$_}, "\n";
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

