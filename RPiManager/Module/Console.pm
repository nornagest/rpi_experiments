#
#===============================================================================
#
#         FILE: Console.pm
#
#  DESCRIPTION:
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (),
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 01/24/2014 08:59:26 PM
#     REVISION: ---
#===============================================================================

#TODO: Use IO::Async, handle STDIN
package Module::Console;
use Modern::Perl 2013;
use Moose;
extends 'Module';

has '+Name' => ( is => 'ro', isa => 'Str', default => 'Console' );
has '+__direction' => ( default => 'Output' );
has '+__type'      => ( default => 'string' );

has 'last_output' => ( is => 'rw', isa => 'Str' );

sub BUILD {
    my $self = shift;
    $self->Manager->add($self);
}

override 'send' => sub {
    my ( $self, $output ) = @_;
    return unless $self->accepts($output);
    my $string = $output->Content->{string};
    return if defined $self->last_output && $self->last_output eq $string;
    say $string;
    $self->last_output($string);
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;

