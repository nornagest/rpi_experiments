#!/usr/bin/perl 
#===============================================================================
#
#         FILE: Config.pl
#
#        USAGE: ./Config.pl  
#
#  DESCRIPTION: Small script to create the default config file
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/27/2014 09:08:31 PM
#     REVISION: ---
#===============================================================================

use Modern::Perl 2013;
use YAML::Tiny;

my $config = YAML::Tiny->new;

$config->[0] = {
    'Module::Clock' => {},
    'Module::Temperature::Client' => {
        'Host' => 'creampi',
        'Port' => 12345,
        'Interval' => 60,
    },
    'Module::Console' => {},
    'Module::PiFace' => {},
};
$config->write("config.yml.default");
