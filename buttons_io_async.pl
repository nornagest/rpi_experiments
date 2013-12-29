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
# create PiFace object
# initialize Channels
# keep state (should be done better than right now)
# handle Inputs
# create Outputs
#
#Routine 1:
# Read PiFace inputs
# on inputs -> send via Channel
#
#Routine 2:
# on input from channel write to PiFace outputs
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

#global state in this case for counter on LEDs
my $state = 0;

my $input_routine = IO::Async::Routine->new(
		channels_in  => [ $in_ch1 ],
		channels_out => [ $out_ch1 ],

		code => sub {
		$out_ch1->send( { 'text' => "Input routine started..." } );
		start();

		my $last_input = 0;
		while(1) {
		my $input = $piface->read_byte();
		if ($input != $last_input ) {
		$out_ch1->send( { 'input' => $input, 'last_input' => $last_input } );
		$last_input = $input;
		}
		usleep(10000);
		}
		},

		on_finish => sub {
		say "Input routine exited.";
		finish();
		},
		);

my $output_routine = IO::Async::Routine->new(
		channels_in  => [ $in_ch2 ],
		channels_out => [ $out_ch2 ],

		code => sub {
		my $output = "Output routine started...";
		$out_ch2->send( \$output );
		start();

		while(1) {
		my $input = ${$in_ch2->recv};
		$piface->write_byte($input);
		}
		},

		on_finish => sub {
		say "Output routine exited.";
		finish();
		},
		);

$loop->add( $input_routine );
$loop->add( $output_routine );

$out_ch1->configure(
		on_recv => sub {
		my ( $ch, $refout ) = @_;
		say "Input routine says: ", $refout->{'text'}
		if(defined $refout->{'text'});
		if(defined $refout->{'input'} && defined $refout->{'last_input'}) {
		my $input = $refout->{'input'};
		my $last_input =  $refout->{'last_input'};
#say "Input: ", $input, " Last input: ", $last_input;
		handle_input($input, $last_input);
		}
		}
		);

$out_ch2->configure(
		on_recv => sub {
		my ( $ch, $output ) = @_;
		say "Output routine says: $$output";
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

sub handle_input {
	my ($input, $last_input) = (@_);
	say $last_input, " -> ", $input;

	my @buttons = (0,0,0,0);
	for my $i (0..3) {
		$buttons[$i] = ($input & (1<<$i)) >> $i;
		if ( $buttons[$i] == 1  && ($last_input & (1 << $i)) == 0 ) {
			handle_button($i);
		}
	}
}

sub handle_button {
    my $button = shift;

    if    ($button == 0) { 
        $state = ($state + 1) % 256 
        say "+1 ($state)";
    } elsif ($button == 1) { 
        $state = ($state - 1) % 256 
        say "-1 ($state)";
    } elsif ($button == 2) { 
        $state = 0 
        say "reset. ($state)";
    } elsif ($button == 3) { 
        say "exit.";
        finish() 
    };

    $in_ch2->send( \$state );
}

