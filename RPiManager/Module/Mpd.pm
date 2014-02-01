#
#===============================================================================
#
#         FILE: Mpd.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/29/2014 08:47:30 PM
#     REVISION: ---
#===============================================================================

package Module::Mpd;

use Modern::Perl 2013;
use Moose;
extends 'Module';
use Net::MPD;

has '+Name' => ( is => 'ro', isa => 'Str', default => 'MPD' );
has '+__direction' => ( default => 'Input' );
has '+__type' => ( default => 'byte' );

has 'Host' => ( is => 'rw', isa => 'Str', default => 'localhost' );
has 'Port' => ( is => 'rw', isa => 'Int', default => 6600 );
has 'Password' => ( is => 'rw', isa => 'Str', default => '' );

has '__mpd' => ( is => 'rw', isa => 'Net::MPD' );

#TODO: Handle input (byte/string)
#TODO: check for MPD updates and print
sub connect {
    my $self = shift;
    my $connect_string = $self->Password . '@' . $self->Host . ':' . $self->Port;
    $self->__mpd = Net::MPD->connect($connect_string);
}

override 'send' => sub {
    my ($self, $input) = @_;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
