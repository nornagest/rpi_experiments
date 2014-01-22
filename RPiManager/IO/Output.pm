#
#===============================================================================
#
#         FILE: Output.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/20/2014 11:08:48 PM
#     REVISION: ---
#===============================================================================

package IO::Output;

use Moose;

use Modern::Perl 2013;
use warnings;
 
has 'Name' => ( is => 'ro', isa => 'Str' );
has 'Type' => ( is => 'ro', isa => 'Str' );
has 'Active' => ( is => 'rw', isa => 'Bool' );
has 'Module' => ( is => 'ro' );

no Moose;
__PACKAGE__->meta->make_immutable;

1;
