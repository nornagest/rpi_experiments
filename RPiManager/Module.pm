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
 
#has 
#input
#output

has 'Name' => ( is => 'rw', isa => 'Str' );
has 'Input' => ( is => 'rw', isa => 'HashRef' );
has 'Output' => ( is => 'rw', isa => 'HashRef' );
has 'Active' => ( is => 'rw', isa => 'Bool' );

sub send_input {};
sub get_output {};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
