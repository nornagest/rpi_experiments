#!/usr/bin/perl

use IO::Async::Loop;
use IO::Async::Signal;
use IO::Async::Timer::Periodic;

my $program = '/opt/vc/bin/raspistill';
my $interval = 300;
my $output = 'cam.jpg';
my %params = (
	'-t' => 2000,      #delay
	'-w' => 1024,      #width
	'-h' => 768,       #height
	'-rot' => 270,     #rotation
	'-ex' => 'night',  #exposure
);

my $loop = IO::Async::Loop->new;
#Timer
my $timer = IO::Async::Timer::Periodic->new(
	interval => $interval,
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
    #TODO: test this
    my epoch = time();
    my $command = $program . join ' ', %params;
    my $final_command = "$command -o ";
    $final_command .= $epoch unless $output eq '-';
    $final_command .= $output;
print $final_command, "\n";
    system($final_command);
}
