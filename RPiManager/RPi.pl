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
#Unit Tests
#use Carp
#add fault tolerance / error handling
#use Exporter 
#===============================================================================
#TODO:
#implement/copy temperature sensors, think about where to put them
#  -> Temperature::Server:XXX
#  -> Device::Temperature::XXX
#implement MMPd module
#dispatch inputs correctly (set modules active/inactive?)
#
#TODO: Modules
# MPD (client) (Net::MPD)
# Temperature::Server
# Temperature::Server::CPU
# Temperature::Server::GPU
# Temperature::Server::DS18B20
# 433MHz
# PIR
# file
# DB
# Web (Mojolicious, Dancer, FCGI)
# Load
# network throughput
# audio volume
# Program
# Service -> SystemD interaction
#===============================================================================
#TODO: Refactoring
#find a decent way to block certain output (per Module/Type) for a time
#TODO:
#show state/errors on (free) upper LEDs
#===============================================================================
#integration with nornagest.org (just transfer info/write info to DB on 
# server/accept requests from server)
#control/integrate camera module on creampi
#===============================================================================
#TODO:
# make list of required (CPAN) modules (by Module)
# give this a decent form (directory structure)
#===============================================================================

use Modern::Perl 2013;
use Data::GUID;
use IO::Async::Loop;
use Manager;
use Module::Console;
use Module::Clock;
use Module::Mpd;
use Module::PiFace;
use Module::Temperature::Client;
use YAML::Tiny;

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

