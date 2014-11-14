#
#===============================================================================
#
#         FILE: DS18B20.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hagen Kuehl (), nornagest[at]gmx.de
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 11/14/2014 06:37:22 PM
#     REVISION: ---
#===============================================================================

package DataSource::DS18B20;
 
use Modern::Perl 2013;
use Moose;
extends 'DataSource';
use File::Slurp;

my $default_dir = '/sys/bus/w1/devices';

has '+name' => ( is => 'rw', isa => 'Str', required => 1 );
has '+type' => ( is => 'rw', isa => 'Str' );
has '+description' => ( is => 'rw', isa => 'Str' );
has 'directory' => ( is => 'rw', isa => 'Str', default => $default_dir );
has '__filename' => ( is => 'rw', isa => 'Str' );

sub BUILD {
    my $self = shift;
    $self->type($self->blessed());
    $self->load_modules() unless (-e $self->directory);
    die unless (-e $self->directory);
    my $file = $self->directory . '/' . $self->name . '/w1_slave';
    $self->__filename($file);
    die unless (-e $self->__filename);
}

sub get_sensors {
  my ($self, $dir) = shift;
  $dir = $default_dir unless defined $dir;
  opendir(my $dh, $dir) or die "Error opening $dir.\n";
  my @devices = readdir($dh);
  closedir($dh);
  return grep { /^28.*/ } @devices;
}

override 'get_value' => sub {
    my $self = shift;
    return $self->get_temp();
};

sub load_modules {
  my $self = shift;
  system("modprobe", "w1-gpio") == 0
    or die "Could not load module w1-gpio.\n";
  system("modprobe", "w1-therm") == 0
    or die "Could not load module w1-therm.\n";
};

sub get_temp {
  my $self = shift;
  my $temp = read_file($self->__filename);
  $temp =~ s/(.*YES.*\n.*t\=)(\d+)(\d{3})(.*)/$2\.$3/;
  chomp $temp;
  return $temp;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
