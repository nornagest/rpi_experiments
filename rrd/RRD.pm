#
#===============================================================================
#
#         FILE: RRD.pm
#
#  DESCRIPTION:
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hagen Kuehl (), nornagest[at]gmx.de
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 11/13/2014 09:28:44 PM
#     REVISION: ---
#===============================================================================

package RRD;

use Modern::Perl 2013;
use Carp;
use Moose;
use RRDTool::OO;
use DataSource;

#my $default_dir = '/var/db/rrd';
#my $default_img_dir = '/usr/share/nginx/rrd';
my $default_dir     = '.';
my $default_rrd_dir = 'rrd';
my $default_img_dir = '/usr/share/images/rrd';
my $step            = 60;

#TODO: move to specific classes
#TODO: make sure only one type per RRD
my %rrd_steps = (
    'DataSource::CPU'     => 5,
    'DataSource::DS18B20' => 60,
);
my %rrd_types = (
    'DataSource::CPU'     => 'GAUGE',
    'DataSource::DS18B20' => 'GAUGE'
);

has 'name'      => ( is => 'rw', isa => 'Str', required => 1, );
has 'directory' => ( is => 'rw', isa => 'Str', default  => $default_dir, );
has 'datasources' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] }
);
has '__filename'     => ( is => 'rw', isa => 'Str', );
has '__img_filename' => ( is => 'rw', isa => 'Str', );
has '__rrd_dir'      => ( is => 'rw', isa => 'Str', );
has '__img_dir'      => ( is => 'rw', isa => 'Str', );
has '__rrd'          => ( is => 'rw', isa => 'RRDTool::OO', );

sub BUILD {
    my $self = shift;
    return unless ( -e $self->directory );

    $self->__rrd_dir( $self->directory . '/' . $default_rrd_dir );
    $self->__img_dir($default_img_dir);

    my $rrd_file = $self->__rrd_dir . '/' . $self->name . '.rrd';
    my $img_file = $self->__img_dir . '/' . $self->name . '.png';
    $self->__filename($rrd_file);
    $self->__img_filename($img_file);

    my $rrd = RRDTool::OO->new( file => $self->__filename );
    $self->__rrd($rrd);

    if ( -e $self->__filename ) {
        say $self->__filename . ' found.';
        my $ds_from_file = $self->__rrd->info()->{'ds'};

        for ( keys %{$ds_from_file} ) {
            push @{ $self->datasources }, DataSource->new( name => $_ );
            say 'Datasource ' . $_ . ' added.';
        }
    }
    else {
        say $self->__filename . ' not found.';
        return unless defined $self->datasources;
        $self->create();
    }
}

sub get_rrds {
    my ( $self, $dir ) = shift;
    $dir = $default_dir . '/' . $default_rrd_dir unless defined $dir;
    opendir( my $dh, $dir ) or croak "Error opening $dir.\n";
    my @rrds = readdir($dh);
    closedir($dh);
    return map { local $_ = $_; s/(.*)\.rrd/$1/; $_ } grep { /^.*\.rrd/ } @rrds;
}

sub create {
    my $self = shift;
    my @arguments;

    push @arguments, 'step';
    push @arguments, $step;

    #push @arguments, $rrd_steps{$self->datasources->[0]->type};

    for ( @{ $self->datasources } ) {
        push @arguments, 'data_source';
        push @arguments, { name => $_->name, type => 'GAUGE' };
    }

    push @arguments,
      (
        archive => {
            rows    => 1440,
            cpoints => 1,
            cfunc   => 'AVERAGE',
        },
        archive => {
            rows    => 1008,
            cpoints => 10,
            cfunc   => 'AVERAGE',
        },
        archive => {
            rows    => 1008,
            cpoints => 120,
            cfunc   => 'AVERAGE',
        },
        archive => {
            rows    => 730,
            cpoints => 720,
            cfunc   => 'AVERAGE',
        },
        archive => {
            rows    => 1825,
            cpoints => 1440,
            cfunc   => 'AVERAGE',
        },
      );

    $self->__rrd->create(@arguments);
    say $self->__filename . ' created.';
}

sub update_rrd {
    my ( $self, $data ) = @_;

    return unless scalar @{ $self->datasources } == scalar @{$data};
    for ( my $i = 0 ; $i < scalar @{$data} ; $i++ ) {
        my $my_ds  = $self->datasources->[$i];
        my $msg_ds = $data->[$i]->{'ds'};
        return unless $msg_ds->{'name'} eq $my_ds->{'name'};
    }

    $self->update_data($data);
}

sub update_data {
    my ( $self, $data ) = @_;

    my @values;
    print "NO DATA!\n" && return unless defined $data->[0];

    my $time = $data->[0]->{'time'};
    for ( @{$data} ) {
        push @values, $_->{'value'};
    }
    $self->__rrd->update( time => $time, values => \@values );
}

sub create_graph {
    my ( $self, $start, $end, $name_addition ) = @_;
    my $filename = $self->__img_filename;
    $filename =~ s/(.*)(\.png)/$1_$name_addition$2/;

    my $last = $self->__rrd->last;
    my $span = $end - $start;

    $end = $last if $last < $end;
    $start = $end - $span;

    my @arguments;

    push @arguments,
      (
        image          => $filename,
        vertical_label => $self->name,
        start          => $start,
        end            => $end,
      );

    for ( @{ $self->datasources } ) {
        my $legend =
          defined $_->{'description'} ? $_->{'description'} : $_->{'name'};
        push @arguments,
          (
            draw => {
                thickness => 2,
                color     => 'FF0000',
                dsname    => $_->{'name'},
                legend    => $legend,
            }
          );
    }

    $self->__rrd->graph(@arguments);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
