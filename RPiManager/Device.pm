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

package Device;
use Moose;

use Modern::Perl 2013;
use warnings;
 
has 'Name' => ( is => 'rw', isa => 'Str' );
#TODO: make this an ArrayRef + add Type
has 'Input' => ( is => 'rw', isa => 'HashRef' );
#TODO: do I really need this?
has 'Output' => ( is => 'rw', isa => 'HashRef' );
has 'Active' => ( is => 'rw', isa => 'Bool' );

sub get_input {};
sub send_output {};

no Moose;
__PACKAGE__->meta->make_immutable;

1;

