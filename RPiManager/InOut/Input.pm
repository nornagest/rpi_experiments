#
#===============================================================================
#
#         FILE: Input.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/22/2014 10:32:06 PM
#     REVISION: ---
#===============================================================================

package InOut::Input;

use Moose;

use Modern::Perl 2013;
use warnings;
 
#name of source Device
has 'Device' => ( is => 'ro', isa => 'Str' );
#Hash of input
has 'Content' => ( is => 'ro', isa => 'HashRef' );

no Moose;
__PACKAGE__->meta->make_immutable;

1;
