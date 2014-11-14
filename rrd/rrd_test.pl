#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: rrd_test.pl
#
#        USAGE: ./rrd_test.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hagen Kuehl (), nornagest[at]gmx.de
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 11/06/2014 08:41:28 PM
#     REVISION: ---
#===============================================================================

use Modern::Perl 2013;
use IO::Async::Loop;
use IO::Async::Timer::Periodic; 
use RRDTool::OO;

# Listener
#   data (list): source (host/service), time, data_source (sensors), value
# Getter
#   connect to host and get data: time, data_source, value
# save_data (list of rrds: hash name => file)
#   insert data into correct rrd
# timer
#   create_graph

my $loop = IO::Async::Loop->new;
my $timer = IO::Async::Timer::Periodic->new(
    interval => 1,
    first_interval => 1,
    on_tick => sub { on_timer(); }, 
);

my $rrd = RRDTool::OO->new(file => "myrrdfile.rrd" );
my $image_file_name = "test.png";

#create_rrd();

$timer->start;
$loop->add( $timer );
$loop->run;

sub on_timer { 
    save_temp();
    create_graph();
}

sub create_rrd { 
    say "Creating RRD";
    $rrd->create(
         step        => 10,  # one-second intervals
         data_source => { name      => "Temp0",
                          type      => "GAUGE" },
         data_source => { name      => "Temp1",
                          type      => "GAUGE" },
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
}

sub update_rrd { 
    say "Updating RRD";
    my $values = shift;
    $rrd->update(values => $values);
}

sub create_graph { 
    say "Creating Graph";
    $rrd->graph(
      image          => $image_file_name,
      vertical_label => 'Temperature',
      start          => time() - 1*3600,
      end            => time(),
      draw           => { thickness => 2, 
        color     => 'FF0000', 
        dsname    => "Temp0", 
        legend    => 'Laptop CPU0 temperature.',
      },
      draw           => { thickness => 2, 
        color     => '00FF00', 
        dsname    => "Temp1", 
        legend    => 'Laptop CPU1 temperature.',
      },
    );
}

sub read_temp { 
    say "Reaing Temperatures";
    my $file1 = '/sys/class/thermal/thermal_zone0/temp';
    open(my $fh1, "<", $file1) or die "Error opening $file1.\n";
    my $temp1 = <$fh1>;
    $temp1 =~ s/(\d+)(\d{3})/$1\.$2/;
    chomp $temp1;

    my $file2 = '/sys/class/thermal/thermal_zone1/temp';
    open(my $fh2, "<", $file2) or die "Error opening $file2.\n";
    my $temp2 = <$fh2>;
    $temp2 =~ s/(\d+)(\d{3})/$1\.$2/;
    chomp $temp2;

    return [$temp1, $temp2];
}

sub save_temp { 
    say "Saving vlues";
    my $values = read_temp();
    for(@{$values}) {
        say "value: $_";
    }
    update_rrd($values);
}

