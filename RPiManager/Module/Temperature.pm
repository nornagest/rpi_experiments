#
#===============================================================================
#
# FILE: Temperature.pm
#
# DESCRIPTION: 
#
# FILES: ---
# BUGS: ---
# NOTES: ---
# AUTHOR: Hagen Kuehl
# ORGANIZATION:
# VERSION: 1.0
# CREATED: 01/16/2014 11:18:09 AM
# REVISION: ---
#===============================================================================

package Module::Temperature;

use Moose;
extends Module;

use Modern::Perl 2013;
use warnings;

has '+Name' => ( is => 'ro', isa => 'Str', default => 'Temperature' );
has '+Type' => ( is => 'ro', isa => 'Str', default => 'byte' );

#TODO: implement
# split into client and Server? Best do this in Input/Output and just keep 
#   functionality here

no Moose;
__PACKAGE__->meta->make_immutable;

1;
