#
#===============================================================================
#
#         FILE: DataSource.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hagen Kuehl (), nornagest[at]gmx.de
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 11/12/2014 07:21:13 PM
#     REVISION: ---
#===============================================================================

package DataSource;
 
use Modern::Perl 2013;
use Moose;
use Scalar::Util qw/blessed/;

has 'name' => ( is => 'rw', isa => 'Str', required => 1 );
has 'type' => ( is => 'rw', isa => 'Str' );
has 'description' => ( is => 'rw', isa => 'Str' );

sub get_value { }

no Moose;
__PACKAGE__->meta->make_immutable;

1;
