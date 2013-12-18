package DS18B20;

use Moose;

use DS18B20::Sensor;

has 'Directory' => (
  is  => 'rw',
  isa => 'Str',
  default => '/sys/bus/w1/devices'
);

has 'Sensors' => (
  is  => 'rw',
  isa => 'ArrayRef',
  default => sub {
    my $self = shift;
    $self->load_modules() unless (-e $self->Directory);
    my @files = $self->get_sensors($self->Directory);
    my @sensors;
    for (@files) {
      push @sensors, DS18B20::Sensor->new(File => $_);
    }
    return \@sensors;
  }
);

sub load_modules {
  my $self = shift;
  system("modprobe", "w1-gpio") == 0
    or die "Could not load module w1-gpio.\n";
  system("modprobe", "w1-therm") == 0
    or die "Could not load module w1-therm.\n";
};

sub get_sensors {
  my $self = shift;
  my $dir = shift;
  opendir(my $dh, $dir) or die "Error opening $dir.\n";
  my @devices = readdir($dh);
  closedir($dh);
  
  my @files;
  for my $dev (@devices) {
    if( $dev =~ m/28.*/ ) {
      my $file = $dir . '/' . $dev . '/w1_slave';
      push @files, $file;
    }
  }
  return @files;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
