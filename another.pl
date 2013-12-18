#!/usr/bin/perl 

use strict;
use warnings;

use Time::HiRes qw(sleep usleep);

use PiFace qw(:all);

pfio_init;

print "Testing outputs...\n";

#my $mask = 10;
#while(1) {
#  my $lastbit = ($mask & (1 << 5)) != 0 ;
#  $mask <<= 1;
#  $mask = $lastbit | $mask;
#  pfio_write_output($mask << 2);
#  sleep(0.05);
#}

for my $count (0..255) {
  my $output = 0;
  for my $i (0..7) {
    my $bit = ((1 << $i) & $count) != 0;
    $output = $output | ($bit << (7 - $i));
  }
  pfio_write_output($output);
  sleep(0.1);
}

#}

pfio_write_output(0);

my $out = pfio_read_output;
print "Outputs before: $out\n";

#while(1) {
  for my $i (0..7) {
    pfio_digital_write($i,1);
    sleep(0.05);
  }

  $out = pfio_read_output;
  print "Outputs inside: $out\n";

  for my $i (0..7) {
    pfio_digital_write($i,0);
    sleep(0.05);
  }
#}

$out = pfio_read_output;
print "Outputs after: $out\n";

print "Reading inputs...\n";

for my $i (0..100) {
  #for my $pin (0..7) {
    #my $in = pfio_digital_read($pin);
    my $in = pfio_read_input;
    #print "Pin " . $pin . " " . $in . "\n"
    #  unless $in == 0;
    print "Input: " . $in . "\n"
      unless $in == 0;
  #}
  sleep(0.1);
}


pfio_deinit;
