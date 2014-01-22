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

package IO::Manager;

use Moose;

use Device;
use Module;
use IO::Output;
use IO::Input;

use Modern::Perl 2013;
use strict;
use warnings;
 
#TODO:
#Device --Input-> Manager --input-> Module
#Device <-Output- Manager <-output- Module
#
#Outputs:
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

has 'Modules' => ( is => 'rw', isa => 'ArrayRef' );
has 'Devices' => ( is => 'rw', isa => 'ArrayRef' );

sub add_module {};
sub remove_module {};
sub activate_module {};
sub deactivate_module {};

sub retrieve_inputs {};
sub retrieve_outputs {};
sub dispatch_inputs {};
sub dispatch_outputs {};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
