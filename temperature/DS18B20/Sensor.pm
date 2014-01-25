package DS18B20::Sensor;

use Moose;
use Modern::Perl 2013;
use File::Slurp;

has 'File' => (
  is  => 'ro',
  isa => 'Str',
);

sub get_temp {
  my $self = shift;
  my $temp = read_file($self->File);
  $temp =~ s/(.*YES.*\n.*t\=)(\d{2})(\d{3})(.*)/$2\.$3/;
  chomp $temp;
  return $temp;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
