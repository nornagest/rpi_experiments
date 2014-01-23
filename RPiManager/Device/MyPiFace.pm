package MyPiFace;

use Moose;

use PiFace qw(:all);

#TODO: encapsulate more
# Init/Deinit automatically
# read  -> reads byte
# write -> writes byte
#
# makr low level functions as such

has 'IsInitialized' => ( is => 'rw', isa => 'Bool', default => 0,);
has 'Inputs' => ( is => 'ro', isa => 'Int',);
has 'Outputs' => ( is => 'rw', isa => 'Int',);

sub init {
  my $self = shift;
  return if $self->IsInitialized;

  pfio_init();
  $self->IsInitialized(1);
}

sub deinit {
  my $self = shift;
  return unless $self->IsInitialized;

  pfio_deinit();
  $self->IsInitialized(0);
}

sub write_byte {
  my $self = shift;
  my $byte = shift;
  return unless $self->IsInitialized;

  pfio_write_output($byte);
}

sub write_bit {
  my $self = shift;
  my $pin = shift;
  my $value = shift;
  return unless $self->IsInitialized;

  pfio_digital_write($pin, $value);
}

sub read_byte {
  my $self = shift;
  return unless $self->IsInitialized;

  return pfio_read_input(); 
}

sub read_bit {
  my $self = shift;
  my $pin = shift;
  return unless $self->IsInitialized;

  return pfio_digital_read($pin);
}

sub read_output_byte {
  my $self = shift;
  return unless $self->IsInitialized;

  return pfio_read_output(); 
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
