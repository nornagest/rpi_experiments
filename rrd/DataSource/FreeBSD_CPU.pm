#
#===============================================================================
#
#         FILE: FreeBSD_CPU.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hagen Kuehl (), nornagest[at]gmx.de
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 11/14/2014 09:37:45 PM
#     REVISION: ---
#===============================================================================

package DataSource::FreeBSD_CPU;
 
use Modern::Perl 2013;
use Moose;
extends 'DataSource';

my $command = 'sysctl -n dev.cpu.CORE.temperature';

has '+name' => ( is => 'rw', isa => 'Str', required => 1 );
has '+type' => ( is => 'rw', isa => 'Str' );
has '+description' => ( is => 'rw', isa => 'Str' );

#TODO: read number of cores
#TODO: load kernel module if necessary
sub BUILD {
    my $self = shift;
    $self->type($self->blessed());
    my $core = $self->name;
    $core =~ s/core//;
    $command =~ s/CORE/$core/;
}

sub get_sensors {
  my ($self, $dir) = shift;
  return ('core0', 'core1', 'core2', 'core3');
}

override 'get_value' => sub {
    my $self = shift;
    my $temp =  `$command`;
    $temp =~ s/C//;
    chomp $temp;
    return $temp;
};

sub get_temp {
  my $self = shift;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
