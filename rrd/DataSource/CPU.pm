#
#===============================================================================
#
#         FILE: CPU.pm
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

package DataSource::CPU;
 
use Modern::Perl 2013;
use Moose;
extends 'DataSource';
use File::Slurp;

my $default_dir = '/sys/class/thermal';

has '+name' => ( is => 'rw', isa => 'Str', required => 1 );
has '+type' => ( is => 'rw', isa => 'Str' );
has '+description' => ( is => 'rw', isa => 'Str' );
has 'directory' => ( is => 'rw', isa => 'Str', default => $default_dir );
has '__filename' => ( is => 'rw', isa => 'Str' );

sub BUILD {
    my $self = shift;
    $self->type($self->blessed());
    die unless (-e $self->directory);
    my $file = $self->directory . '/' . $self->name . '/temp';
    $self->__filename($file);
    die unless (-e $self->__filename);
}

sub get_sensors {
  my ($self, $dir) = shift;
  $dir = $default_dir unless defined $dir;
  opendir(my $dh, $dir) or die "Error opening $dir.\n";
  my @devices = readdir($dh);
  closedir($dh);
  return grep { /^thermal_zone.*/ } @devices;
}

override 'get_value' => sub {
    my $self = shift;
    return $self->get_temp();
};

sub get_temp {
  my $self = shift;
  my $temp = read_file($self->__filename);
  $temp =~ s/(\d+)(\d{3})/$1\.$2/;
  chomp $temp;
  return $temp;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
