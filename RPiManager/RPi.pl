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
#Make modules configurable -> config file
#better encapsulation
# => Notifier::Listener
# => hide reading temperature over network somehow
#
#TODO: Finish refactoring
#move everything so far to Manager
#make Modules real Modules
#remove all say except for debugging and in upcoming InOut::Console
#  even better: handle debug output via InOut::Console
#
#TODO: think about additional output, like state!
#------
#Devices ( PiFace / GPIO / Sensors / Console / DB )
#Notifier: encapsulate IO::Async implementation
#Modules: implement Functionality 
#------
#Main/Reactor: build a state machine for handling stuff
# keep main state
# manage inputs + outputs -> more or less in InOut::Manager
# keep track of modules
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
#kill subprocess/routine on exit
#===============================================================================
#other modules with PiFace output:
#temperature load audio_volume
#
#more Modules:
#manage programs/services module (indicators via LEDs, start/stop via buttons)
#read/request info from other hosts/programs via sockets 
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

use Manager;
use InOut::PiFace;

use Notifier::Timer;
use IO::Async::Loop;
use IO::Async::Stream;
use Storable qw(thaw);
use Data::GUID;
#my $guid = Data::GUID->new;
#my $guid_string = $guid->as_string;

my $last_output;
#TODO: handle this inside Manager
#change this into some kind of semaphore and ideally make it kind of safe
#think about multiple button presses -> $block_output++
#remeber last timer and replace or queue new timer
my $block_output = 0; #don't override output of main

my $loop = IO::Async::Loop->new;
my $manager = Manager->new( 'Loop' => $loop );
my $clock = Module::Clock->new( 'GUID' => Data::GUID->new->as_string,
    'Manager' => $manager, 'output_ref' => \&sub_output);
$manager->add_module( $clock );
my $piface = InOut::PiFace->new( 
    'Manager' => $manager, 'GUID' => Data::GUID->new->as_string );
$manager->add_inout( $piface );

&create_and_add_notifiers;
say "Ready...";
$clock->print_state();

$loop->run;

#===============================================================================

sub create_and_add_notifiers() {
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

#Do this in InOut::Manager
sub handle_input($$) {
    my ($input, $last_input) = @_;
    say "RPi handle_input";
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
    #TODO: send this to InOut::Manager
#    $out_ch->send( \$value ) unless defined $last_output && $value == $last_output;
    $last_output = $value;
}

sub finish {
    $loop->stop;
    main_output(0, 1);
    say "Goodbye!";
}

