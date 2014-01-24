#
#===============================================================================
#
#         FILE: Device.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/21/2014 09:57:37 PM
#     REVISION: ---
#===============================================================================

#TODO: extract most of this as a role
package InOut;
use Moose;

use Modern::Perl 2013;
use warnings;
 
has 'Name' => ( is => 'ro', isa => 'Str', required => 1 );
has 'GUID' => ( is => 'ro', isa => 'Str', required => 1 );
#TODO: seperate Input and Output types, allow multiple
has 'Type' => ( is => 'ro', isa => 'Str', required => 1 );
has 'Manager' => ( is => 'ro', isa => 'Object', required => 1 );
has 'Active' => ( is => 'rw', isa => 'Bool', default => 1 );

sub write {
    my ($self, $output) = @_;
    say "InOut write $output";
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;

