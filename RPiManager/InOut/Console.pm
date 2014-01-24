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

package InOut::Console;

use Moose;
extends 'InOut';

use Modern::Perl 2013;
use warnings;
 
has '+Name' => ( is => 'ro', isa => 'Str', default => 'PiFace' );
has '+Type' => ( is => 'ro', isa => 'Str', default => 'byte' );
has 'last_output' => ( is => 'rw', isa => 'Str' );

override 'write' => sub {
    my ($self, $output) = @_;
    my $string = $output->{string} if defined $output->{string};
    return if defined $self->last_output && $self->last_output eq $string;
    say "Console $string";
    $self->last_output($string);
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;

