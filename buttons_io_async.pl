#!/usr/bin/perl 
#===============================================================================
#
#         FILE: io_async_routine.pl
#
#        USAGE: ./io_async_routine.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 12/29/2013 12:48:50 PM
#     REVISION: ---
#===============================================================================

use Modern::Perl 2013;
use warnings;

use MyPiFace;

use IO::Async::Channel;
use IO::Async::Loop;
use IO::Async::Routine;
use Time::HiRes qw(sleep usleep);

#Main:
# initialize PiFace (?)
# initialize Channels
#
#Routine 1:
# Read PiFace inputs
# on inputs -> send via Channel
#
#Routine 2:
# on input write to PiFace outputs
#
#Signal:
# handle external Signals
# Stop/Restart
#
#Timer:
# Check PulseAudio regularly
# play/stop on time
#
#Stream/Socket
# for inputs via web interface

my $piface = MyPiFace->new;

my $loop = IO::Async::Loop->new;

my $in_ch1 = IO::Async::Channel->new;
my $out_ch1  = IO::Async::Channel->new;
my $in_ch2 = IO::Async::Channel->new;
my $out_ch2  = IO::Async::Channel->new;

my $routine1 = IO::Async::Routine->new(
   channels_in  => [ $in_ch1 ],
   channels_out => [ $out_ch1 ],
 
   code => sub {
       say "Routine 1 started...";
       my $output = "Just checking...";
       $out_ch1->send( { 'text' => $output } );

start();

       my $lastInput = 0;
       while(1) {
           my $input = $piface->read_byte();
           if ($input != $lastInput ) {
               $out_ch1->send( { 'input' => $input, 'lastInput' => $lastInput } );
               $lastInput = $input;
           }
           usleep(10000);
       }
       return;
   },
 
   on_finish => sub {
      say "Routine1 exited.";
      finish();
   },
);

my $routine2 = IO::Async::Routine->new(
   channels_in  => [ $in_ch2 ],
   channels_out => [ $out_ch2 ],
 
   code => sub {
       say "Routine 2 started...";
       my $output = "Just checking...";
       $out_ch2->send( \$output );

start();
           #my $input = ${$in_ch->recv};
           #$out_ch->send( \$input );

       say "Routine 2 waiting for 10s...";
       sleep(10);
   },
 
   on_finish => sub {
      say "Routine2 exited.";
      finish();
   },
);
 
$loop->add( $routine1 );
$loop->add( $routine2 );

#my $test = "Test.";
#$in_ch->send( \$test );

$out_ch1->configure(
   on_recv => sub {
      my ( $ch, $refout ) = @_;
      say "Output of Routine 1: ", $refout->{'text'}
         if(defined $refout->{'text'});
      say "Input: ", $refout->{'input'}, " Last input: ", $refout->{'lastInput'}
         if(defined $refout->{'input'} && defined $refout->{'lastInput'});
   }
);

$out_ch2->configure(
   on_recv => sub {
      my ( $ch, $output ) = @_;
      say "Output of Routine 2: $$output";
   }
);

$loop->run;

sub start {
    say "Initializing PiFace...";
    $piface->init;
}

sub finish {
    $piface->deinit;
    $loop->stop;
    say "Goodbye!";
}
