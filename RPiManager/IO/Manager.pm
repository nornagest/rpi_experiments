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
#retrieve_inputs()
#get inputs from registered Devices
#send to registered Modules
#
#Device --Input-> Manager --input-> Module
#
#dispatch_outputs()
#get outputs from registered Modules
#send to registered Devices
#
#Device <-Output- Manager <-output- Module

#list of Modules
has 'Modules' => ( is => 'rw', isa => 'ArrayRef' );
#list of Devices
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
