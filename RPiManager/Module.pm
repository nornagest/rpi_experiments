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

package Module;
use Modern::Perl 2013;
use Moose;

has 'Manager' => ( is => 'ro', isa => 'Manager', required => 1 );
has 'Name'    => ( is => 'ro', isa => 'Str',     required => 1 );
has 'GUID'    => ( is => 'ro', isa => 'Str',     required => 1 );

has '__direction' => ( is => 'ro', isa => 'Str' );
has '__type'      => ( is => 'ro', isa => 'Str' );

sub accepts {
    my ( $self, $message ) = @_;
    return 0 unless $message->Direction eq $self->__direction;
    return 0 unless grep $_ eq $self->__type, keys %{$message->Content};
    return 1;
}

sub send {
    my ( $self, $output ) = @_;
    say "Module write";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

