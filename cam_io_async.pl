#!/usr/bin/perl

use IO::Async::Loop;
use IO::Async::Signal;
use IO::Async::Timer::Periodic;

my %params = (
	'program' => '/opt/vc/bin/raspistill',
	'interval' => 300,
	'delay' => 2000,
	'width' => 1024,
	'height' => 768,
	'rotation' => 270,
	'exposure' => 'night',
	'name' => 'cam.jpg',
);

my $command = $params{'program'} .
	' -t ' . $params{'delay'} .
	' -w ' . $params{'width'} .
	' -h ' . $params{'height'} .
	' -rot ' . $params{'rotation'} .
	' -ex '. $params{'exposure'} .
	' -o ';

my $loop = IO::Async::Loop->new;
#Timer
my $timer = IO::Async::Timer::Periodic->new(
	interval => $params{'interval'},
	first_interval => 0,
	on_tick => \&take_pic,
);
$timer->start;
$loop->add($timer);
#SIGHUP
my $sighup = IO::Async::Signal->new(
   name => "HUP",
   on_receipt => \&take_pic,
);
$loop->add($sighup);
#SIGTERM
my $sigterm = IO::Async::Signal->new(
   name => "TERM",
   on_receipt => sub {
	   $loop->stop;
   },
);
$loop->add($sigterm);
#run
$loop->run();
#subs
sub take_pic {
    my $epoch = time();
    my $final_command = $command . ' '. $epoch .'_'. $params{'name'};
print $final_command, "\n";
    system($final_command);
}
