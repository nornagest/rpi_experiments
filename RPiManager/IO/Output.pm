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
 
#name of source Module
has 'Module' => ( is => 'ro', isa => 'Str' );
#Hash of output
has 'Content' => ( is => 'ro', isa => 'HashRef' );

no Moose;
__PACKAGE__->meta->make_immutable;

1;
