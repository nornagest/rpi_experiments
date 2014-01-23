#
#===============================================================================
#
#         FILE: Module.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/21/2014 09:56:45 PM
#     REVISION: ---
#===============================================================================

package Module;
use Moose;

use Modern::Perl 2013;
use warnings;
 
has 'Name' => ( is => 'ro', isa => 'Str', required => 1 );
has 'GUID' => ( is => 'ro', isa => 'Str', required => 1 );
has 'Type' => ( is => 'ro', isa => 'Str', required => 1 );
has 'Active' => ( is => 'rw', isa => 'Bool', default => 1 );
has 'Manager' => ( is => 'ro', isa => 'Object', required => 1 );

sub send_input {};

no Moose;
__PACKAGE__->meta->make_immutable;

1;

