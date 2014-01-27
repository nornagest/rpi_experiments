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
#MPD module
#TODO: 
#find a decent way to block certain output (per Module/Type) for a time
#TODO: 
#use Carp
#add fault tolerance / error handling
#use Exporter 
#Unit Tests
#TODO:
#show state/errors on (free) upper LEDs
#------
#Modules: PiFace / 433MHz / GPIO / Sensors / Console / DB / File
#Notifier: encapsulate IO::Async implementation
#Modules: implement Functionality 
#------
#Main/Reactor: build a state machine for handling stuff
# keep main state
# manage Modules and Modules
#===============================================================================
#other modules with PiFace output:
#temperature load audio_volume
#------
#more Modules:
#MPD via Net::MPD
#manage programs/services module (indicators via LEDs, start/stop via buttons)
#read/request info from other hosts/programs via sockets 
#write information to DB/file
#------
#web frontend (first just output, then control)
#integration with nornagest.org (just transfer info/write info to DB on 
# server/accept requests from server)
#------
#control/integrate camera module on creampi
#run on creampi
# i/o web frontend
# upload to nornagest.org
#===============================================================================

use Modern::Perl 2013;
use Data::GUID;
use IO::Async::Loop;
use Manager;
use Module::PiFace;
use Module::Console;
use Module::Clock;
use Module::Temperature::Client;
use YAML::Tiny;
#WebCam
#Web -> Mojo? Dancer? Listener? HTTP::Server?

my $config_file = -e "config.yml" ? "config.yml" : "config.yml.default";
say "Using $config_file";

my $loop = IO::Async::Loop->new;
my $manager = Manager->new( 'Loop' => $loop );
my $config = YAML::Tiny->read($config_file);

for my $module (keys $config->[0]) {
    $config->[0]->{$module}->{'Manager'} = $manager;
    $config->[0]->{$module}->{'GUID'} = Data::GUID->new->as_string;

    say "Loading $module";
    $module->new(%{ $config->[0]->{$module} } );
};

#Module::Clock->new(  'Manager' => $manager,  'GUID' => Data::GUID->new->as_string ) ;
#Module::Temperature::Client->new( 'Manager' => $manager, 'GUID' => Data::GUID->new->as_string );
#Module::PiFace->new( 'Manager' => $manager, 'GUID' => Data::GUID->new->as_string );
#Module::Console->new( 'Manager' => $manager, 'GUID' => Data::GUID->new->as_string ) ;

say "Ready...";
$loop->run;

#===============================================================================
#TODO: (in Module)
#block other Module outputs (handle this in Manager)
sub blink($$) {
    my ($value, $interval) = @_;
    my $ticker = Notifier::Timer::create_timer_periodic($interval, 0, 
        sub {}); #TODO: implement and make this a Module
}

