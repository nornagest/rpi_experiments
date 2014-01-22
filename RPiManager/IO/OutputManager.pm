#
#===============================================================================
#
#         FILE: OutputManager.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/13/2014 08:12:21 PM
#     REVISION: ---
#===============================================================================

package IO::OutputManager;

use Moose;

use IO::Output;

use Modern::Perl 2013;
use strict;
use warnings;
 
#TODO:
#has Modules name, output type, active, Module reference
#Methods:
#add_module
#remove_module
#activate_module
#deactivate_module
#write/print
#
#knowns Devices
#  Device has accepted_types
#knows Modules
#  retrieves output from module and maps to devices



no Moose;
__PACKAGE__->meta->make_immutable;

1;
