#
#===============================================================================
#
#         FILE: Message.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/25/2014 11:30:48 AM
#     REVISION: ---
#===============================================================================

package Message;

use Moose;

use Modern::Perl 2013;
use warnings;

has 'Source' => ( is => 'ro', isa => 'Str', required => 1 );
has 'Direction' => ( is => 'ro', isa => 'Str', required => 1 );
has 'Content' => ( is => 'ro', isa => 'HashRef', required => 1 );

no Moose;
__PACKAGE__->meta->make_immutable;

1;

