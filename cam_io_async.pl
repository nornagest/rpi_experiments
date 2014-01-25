#!/usr/bin/perl

use Modern::Perl 2013;
use warnings; 

use POSIX qw(strftime);
use IO::Async::Loop;
use IO::Async::Signal;
use IO::Async::Timer::Periodic;

my $program = '/opt/vc/bin/raspistill';
my $interval = 900;
my $output_dir = '/usr/share/nginx/img';
my $output = '_cam.jpg';
my %params = (
	'-n' => '', #no preview
	'-t' => 1000,      #delay
	'-w' => 1280,      #width
	'-h' => 960,       #height
	'-rot' => 90,     #rotation
#	'-ex' => 'night',  #exposure
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
	   say "Bye.";
   },
);
$loop->add($sigterm);
#SIGINT
my $sigint = IO::Async::Signal->new(
   name => "INT",
   on_receipt => sub {
	   $loop->stop;
	   say "Bye.";
   },
);
$loop->add($sigint);
#run
$loop->run();
#subs
sub take_pic {
    my $time = strftime "%Y%m%d-%H%M%S", localtime;
    my $command = $program . ' ' . join ' ', %params;
    my $final_command = "$command -o " . $output_dir . '/';
    $final_command .= $time unless $output eq '-';
    $final_command .= $output;
    say $final_command;
    system($final_command);
}
