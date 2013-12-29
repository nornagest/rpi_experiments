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
start;

my $loop = IO::Async::Loop->new;

my $in_ch1 = IO::Async::Channel->new;
my $out_ch1  = IO::Async::Channel->new;
my $in_ch2 = IO::Async::Channel->new;
my $out_ch2  = IO::Async::Channel->new;

my $routine1 = IO::Async::Routine->new(
   channels_in  => [ $in_ch1 ],
   channels_out => [ $out_ch1 ],
 
   code => sub {
           #my $input = ${$in_ch->recv};
           #$out_ch->send( \$input );
       }
   },
 
   on_finish => sub {
      say "Routine1 exited.";
      finish;
   },
);

my $routine2 = IO::Async::Routine->new(
   channels_in  => [ $in_ch2 ],
   channels_out => [ $out_ch2 ],
 
   code => sub {
           #my $input = ${$in_ch->recv};
           #$out_ch->send( \$input );
       }
   },
 
   on_finish => sub {
      say "Routine2 exited.";
      finish;
   },
);
 
$loop->add( $routine1 );
$loop->add( $routine2 );

#my $test = "Test.";
#$in_ch->send( \$test );

$out_ch1->configure(
   on_recv => sub {
      my ( $ch, $output ) = @_;
      #say "Routine said: $$output";
      #$loop->stop;
   }
);

$loop->run;

sub start {
    $piface->init;
}

sub finish {
    $piface->deinit;
    $loop->stop;
}
