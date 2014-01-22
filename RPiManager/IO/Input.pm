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

package IO::Input;

use Moose;

use Modern::Perl 2013;
use warnings;
 
has 'Device' => ( is => 'ro', isa => 'Str' );
has 'Content' => ( is => 'ro', isa => 'HashRef' );

no Moose;
__PACKAGE__->meta->make_immutable;

1;
