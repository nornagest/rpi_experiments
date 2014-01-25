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
#more type checking
#TODO: 
#find a decent way to block certain output (per Module/Type) for a time
#TODO:
#Make modules configurable -> config file
#TODO: 
#move everything so far to Manager
#make Modules real Modules
#remove all say except for debugging
#  even better: handle debug output via Module::Console
#------
#Modules: PiFace / 433MHz / GPIO / Sensors / Console / DB / File
#Notifier: encapsulate IO::Async implementation
#Modules: implement Functionality 
#------
#Main/Reactor: build a state machine for handling stuff
# keep main state
# manage Modules and Modules
#===============================================================================
#add fault tolerance / error handling
#use Exporter 
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
#control/integrate camera module on creampi
#run on creampi
# i/o web frontend
# upload to nornagest.org
#===============================================================================

use Modern::Perl 2013;
use warnings;

use Data::GUID;
use IO::Async::Loop;
use Manager;
use Module::PiFace;
use Module::Console;
use Module::Clock;
#Temperature
#WebCam
#Web -> Mojo? Dancer? Listener? HTTP::Server?

my $loop = IO::Async::Loop->new;
my $manager = Manager->new( 'Loop' => $loop );

$manager->add( Module::Clock->new( 
        'GUID' => Data::GUID->new->as_string, 'Manager' => $manager, 
        'output_ref' => \&sub_output) );
$manager->add( Module::PiFace->new( 
        'Manager' => $manager, 'GUID' => Data::GUID->new->as_string ) );
$manager->add( Module::Console->new( 
        'Manager' => $manager, 'GUID' => Data::GUID->new->as_string ) );

&create_and_add_notifiers;

say "Ready...";
$loop->run;

#===============================================================================
#TODO: Move this to Notifier and Module
# => Notifier::Listener
# => hide reading temperature over network somehow
#===============================================================================
sub create_and_add_notifiers() {
    my $temp_ticker = Notifier::Timer::create_timer_periodic( 60, 0, sub { on_tick() } );
    $loop->add( $temp_ticker );
}

use Notifier::Timer;
use IO::Async::Stream;
use Storable qw(thaw);

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
        say $_, " => ", $temp->{"sensors"}{$_};
    }
}

#===============================================================================
#TODO: (in Module)
#block other Module outputs (handle this in Manager)
sub blink($$) {
    my ($value, $interval) = @_;
    my $ticker = Notifier::Timer::create_timer_periodic($interval, 0, 
        sub {}); #TODO: implement and make this a Module
}

