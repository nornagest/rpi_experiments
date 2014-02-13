package Device::MyPiFace;
use Modern::Perl 2013;
use Moose;

#TODO: Use Term::TermKey(::Async)
use Term::ReadKey;

has 'IsInitialized' => ( is => 'rw', isa => 'Bool', default => 0, );

#destructor
sub DEMOLISH {
    my $self = shift;
    $self->deinit;
}

sub get_key {
    ReadMode 'raw';
    my $input = ReadKey(0);
    ReadMode 'restore';
    chomp $input;
    return $input;
}

sub init {
    my $self = shift;
    say "MyNoPiFace init";
    return if $self->IsInitialized;
    say "MyNoPiFace init really";
    $self->IsInitialized(1);
}

sub deinit {
    my $self = shift;
    say "MyNoPiFace deinit";
    return unless $self->IsInitialized;
    say "MyNoPiFace deinit really";
    $self->IsInitialized(0);
}

sub write_byte {
    my ( $self, $byte ) = @_;
    return unless $self->IsInitialized;
    $| = 1;
    say "\tPiFace: $byte";
    $| = 0;
}

sub write_bit {
    my ( $self, $pin, $value ) = @_;
    return unless $self->IsInitialized;
    $| = 1;
    say "\tPiFace: $pin $value";
    $| = 0;
}

sub read_byte {
    my $self = shift;
    return unless $self->IsInitialized;
    return get_key();
}

sub read_bit {
    my ( $self, $pin ) = @_;
    return unless $self->IsInitialized;
    return get_key();
}

sub read_output_byte {
    my $self = shift;
    return unless $self->IsInitialized;
    return get_key();
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
