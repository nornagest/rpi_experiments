#
#===============================================================================
#
# FILE: Temperature.pm
#
# DESCRIPTION: 
#
# FILES: ---
# BUGS: ---
# NOTES: ---
# AUTHOR: Hagen Kuehl
# ORGANIZATION:
# VERSION: 1.0
# CREATED: 01/16/2014 11:18:09 AM
# REVISION: ---
#===============================================================================

package Module::Temperature;
use Modern::Perl 2013;
use Moose;
extends 'Module';

has '+Name' => ( is => 'ro', isa => 'Str', default => 'Temperature' );
has '+__direction' => ( default => '' );
has '+__type' => ( default => '' );
has 'Port' => ( is => 'ro', isa => 'Int', default => '12345' );
has 'Host' => ( is => 'ro', isa => 'Str', default => 'creampi' );

#TODO: Make use of temperature devices

no Moose;
__PACKAGE__->meta->make_immutable;

1;
