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
#      CREATED: 01/25/2014 11:22:40 AM
#     REVISION: ---
#===============================================================================

package Message::Output;

use Moose;
extends 'Message';

use Modern::Perl 2013;
use warnings;

has '+Direction' => ( default => 'Output' );

no Moose;
__PACKAGE__->meta->make_immutable;

1;

