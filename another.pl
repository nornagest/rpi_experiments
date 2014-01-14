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

#Here starts the temporary version of a webcam program
#!/usr/bin/perl

use IO::Async::Loop;
use IO::Async::Signal;
use IO::Async::Timer::Periodic;

my $loop = IO::Async::Loop->new;
my $timer = IO::Async::Timer::Periodic->new(
	interval => 30,
	first_interval => 0,
	on_tick => \&take_pic,
);
$timer->start;
$loop->add($timer);
my $sighup = IO::Async::Signal->new(
   name => "HUP",
   on_receipt => \&take_pic,
);
$loop->add($sighup);
my $sigterm = IO::Async::Signal->new(
   name => "TERM",
   on_receipt => sub {
	   $loop->stop;
   },
);
$loop->add($sigterm);

$loop->run();

sub take_pic {
    my $epoch = time();
    system("/opt/vc/bin/raspistill -t 2000 -rot 270 -ex night -w -h -o ${epoch}cam.jpg");
}

