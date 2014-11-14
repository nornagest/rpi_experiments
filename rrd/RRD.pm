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
use Moose;
use RRDTool::OO;
use DataSource;

#my $default_dir = '/var/db/rrd';
my $default_dir = '.';
#TODO: move to specific classes
#TODO: make sure only one type per RRD
my %rrd_steps = ( 
    'DataSource::CPU' => 5, 
    'DataSource::DS18B20' => 300 
);
my %rrd_types = ( 
    'DataSource::CPU' => 'GAUGE', 
    'DataSource::DS18B20' => 'GAUGE' 
);

has 'name' => ( is => 'rw', isa => 'Str', required => 1, );
has 'directory' => ( is => 'rw', isa => 'Str', default => $default_dir, );
has 'datasources' => ( is => 'rw', isa => 'ArrayRef', required => 1, );
has '__filename' => ( is => 'rw', isa => 'Str', );
has '__rrd' => ( is => 'rw', isa => 'RRDTool::OO', );

sub BUILD {
    my $self = shift;
    die unless (-e $self->directory);

    my $file = $self->directory . '/' . $self->name . '.rrd';
    $self->__filename($file);

    my $rrd = RRDTool::OO->new( file => $self->__filename );
    $self->__rrd($rrd);
    $self->create() unless (-e $self->__filename);
}

sub create {
    my $self = shift;
    my @arguments;

    push @arguments, 'step';
    push @arguments, $rrd_steps{$self->datasources->[0]->type};

    for(@{$self->datasources}) {
        push @arguments, 'data_source';
        push @arguments, { name => $_->name, type => 'GAUGE' };
    }

    push @arguments, (
         archive     => { rows      => 12,
                         cpoints   => 1,
                         cfunc     => 'AVERAGE',
                        },
         archive     => { rows      => 288,
                         cpoints   => 1,
                         cfunc     => 'AVERAGE',
                        },
         archive     => { rows      => 168,
                         cpoints   => 12,
                         cfunc     => 'AVERAGE',
                        },
         archive     => { rows      => 720,
                         cpoints   => 12,
                         cfunc     => 'AVERAGE',
                        },
         archive     => { rows      => 365,
                         cpoints   => 288,
                         cfunc     => 'AVERAGE',
                        },
    );

    use Data::Dumper;
    say Dumper(@arguments);
    $self->__rrd->create(@arguments);
}

sub update_rrd { 
    my ($self, $values) = @_;
    say "Updating RRD";
    $self->__rrd->update(values => $values);
}

sub create_graph { 
    my $self = shift;
    say "Creating Graph";
}

sub update {
    my $self = shift;
}

sub graph {
    my $self = shift;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
