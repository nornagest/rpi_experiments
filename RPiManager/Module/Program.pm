#
#===============================================================================
#
# FILE: Program.pm
#
# DESCRIPTION: 
#
# FILES: ---
# BUGS: ---
# NOTES: ---
# AUTHOR: Hagen Kuehl
# ORGANIZATION:
# VERSION: 1.0
# CREATED: 01/24/2014 11:18:09 AM
# REVISION: ---
#===============================================================================

package Module::Program;

use Moose;

use Modern::Perl 2013;
use warnings;

#TODO: implement
# split into client and Server? Best do this in Input/Output and just keep 
#   functionality here

no Moose;
__PACKAGE__->meta->make_immutable;

1;
