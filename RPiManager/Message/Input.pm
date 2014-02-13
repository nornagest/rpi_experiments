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
#      CREATED: 01/25/2014 11:22:31 AM
#     REVISION: ---
#===============================================================================

package Message::Input;
use Modern::Perl 2013;
use Moose;
extends 'Message';

has '+Direction' => ( default => 'Input' );

no Moose;
__PACKAGE__->meta->make_immutable;

1;

