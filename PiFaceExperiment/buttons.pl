#!/usr/bin/perl 

use feature ":5.10";
use strict;
use warnings;

use Time::HiRes qw(sleep usleep);

use PiFace qw(:all);

pfio_init;

my $lastInput = 0;
my $state = 0;

while (1) {
  my $input = pfio_read_input();
  if ($input != $lastInput) {
    handle_input($input, $lastInput);
    $lastInput = $input;
  } 
  usleep(1000);
}

sub handle_input {
  my ($input, $lastInput) = (@_);
  
  #print "Input: $input\t$lastInput\t$state\n";

  my @buttons = (0,0,0,0);
  for my $i (0..3) {
    $buttons[$i] = ($input & (1<<$i)) >> $i;
    if ( $buttons[$i] == 1  && ($lastInput & (1 << $i)) == 0 ) {
      handle_button($i);
    }
  }
}

sub handle_button {
  my $button = shift;

  if    ($button == 0) { $state = ($state + 1) % 256 }
  elsif ($button == 1) { $state = ($state - 1) % 256 }
  elsif ($button == 2) { $state = 0 }
  elsif ($button == 3) { finalize() };

  pfio_write_output($state);
}

sub finalize {
  pfio_write_output(0);
  pfio_deinit;
  exit(0);
}
