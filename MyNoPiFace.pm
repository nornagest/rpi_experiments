package MyPiFace;

use Moose;

use Term::ReadKey;

has 'IsInitialized' => (
  is => 'rw',
  isa => 'Bool',
  default => 0,
);

has 'Inputs' => (
  is => 'ro',
  isa => 'Int',
);

has 'Outputs' => (
  is => 'rw',
  isa => 'Int',
);

sub init {
  my $self = shift;
  return if $self->IsInitialized;

  $self->IsInitialized(1);
}

sub deinit {
  my $self = shift;
  return unless $self->IsInitialized;

  $self->IsInitialized(0);
}

sub write_byte {
  my $self = shift;
  my $byte = shift;
  return unless $self->IsInitialized;

  $| = 1;
  print "$byte\n";
  $| = 0;
}

sub write_bit {
  my $self = shift;
  my $pin = shift;
  my $value = shift;
  return unless $self->IsInitialized;

  $| = 1;
  print "$pin $value\n";
  $| = 0;
}

sub read_byte {
  my $self = shift;
  return unless $self->IsInitialized;

  return get_key();
}

sub read_bit {
  my $self = shift;
  my $pin = shift;
  return unless $self->IsInitialized;

  return get_key();
}

sub read_output_byte {
  my $self = shift;
  return unless $self->IsInitialized;

  return get_key();
}

sub get_key {
  ReadMode 'raw';
  my $input = ReadKey(0);
  ReadMode 'restore';
  chomp $input;
  return $input; 
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
