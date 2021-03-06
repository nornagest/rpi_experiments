package Device::MyPiFace;
use Modern::Perl 2013;
use Moose;
use PiFace qw(:all);

has 'IsInitialized' => ( is => 'rw', isa => 'Bool', default => 0, );

#destructor
sub DEMOLISH {
    my $self = shift;
    $self->deinit;
}

sub init {
    my $self = shift;
    say "MyPiFace init";
    return if $self->IsInitialized;
    say "MyPiFace init really";
    pfio_init();
    $self->IsInitialized(1);
}

sub deinit {
    my $self = shift;
    say "MyPiFace deinit";
    return unless $self->IsInitialized;
    say "MyPiFace deinit really";
    pfio_deinit();
    $self->IsInitialized(0);
}

sub write_byte {
    my ( $self, $byte ) = @_;
    return unless $self->IsInitialized;
    pfio_write_output($byte);
}

sub write_bit {
    my ( $self, $pin, $value ) = @_;
    return unless $self->IsInitialized;
    pfio_digital_write( $pin, $value );
}

sub read_byte {
    my $self = shift;
    return unless $self->IsInitialized;
    return pfio_read_input();
}

sub read_bit {
    my ( $self, $pin ) = @_;
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
