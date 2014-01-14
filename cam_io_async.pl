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

