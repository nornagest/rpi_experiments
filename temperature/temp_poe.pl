#!/usr/bin/perl

use strict;
use warnings;

use DS18B20;

use POE;

#Main Session
# load mosules, get sensors
# start timer
# on tick -> read temp
# handle temp -> STDOUT, SQLite
POE::Session->create(
  inline_states => {
    _start => \&main_start,
    tick   => \&main_tick,
    temp   => \&main_temp,
  },
);

sub main_start {
  $_[KERNEL]->alias_set('main');
  print "Start main.\n";

  my $time = time();
  $_[HEAP]->{time} = $time;
  $_[HEAP]->{ds18b20} = DS18B20->new();
  $_[KERNEL]->alarm( tick => $time);
}

sub main_tick {
  #print "Tick main.\n";

  for my $sensor (@{$_[HEAP]->{ds18b20}->Sensors}) {
    $_[KERNEL]->post('reader', 'read', $sensor);
  }

  $_[HEAP]->{time} += 300;
  $_[KERNEL]->alarm( tick => $_[HEAP]->{time});
}

sub main_temp {
  #print "Temp main.\n";
  $_[KERNEL]->post('writer', 'write', $_[ARG0], $_[ARG1], scalar localtime());
}

#Add session for interactive input
# POE::Wheel""ReadLine
# close program
# print current temperature

#Reader Session
# on event read sensor(s)
POE::Session->create(
  inline_states => {
    _start => \&reader_start,
    read   => \&reader_read,
  },
);

sub reader_start {
  $_[KERNEL]->alias_set('reader');
  print "Start reader.\n";
}

sub reader_read {
  #print "Read reader.\n";
  $_[KERNEL]->post(
    'main', 
    'temp', 
    $_[ARG0]->get_temp(),
    $_[ARG0]->File
  );
}

#Writer Session
# write temp to STDOUT
POE::Session->create(
  inline_states => {
    _start => \&writer_start,
    write  => \&writer_write,
  },
);

sub writer_start {
  $_[KERNEL]->alias_set('writer');
  print "Start writer.\n";
}

sub writer_write {
  #print "Write writer.\n";
  print $_[ARG2], " - ", $_[ARG1], " - ", $_[ARG0], "°C\n";
}

#DB Session
# write temp to DB

$poe_kernel->run();
