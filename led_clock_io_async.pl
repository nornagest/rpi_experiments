#!/usr/bin/perl 
#===============================================================================
#
#         FILE: led_clock_io_async.pl
#
#        USAGE: ./led_clock_io_async.pl  
#
#  DESCRIPTION: Show time in binary format with PiFace LEDs, switch between
#               hour, minute and second display on button press
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hagen Kuehl
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/08/2014 10:59:45 PM
#     REVISION: ---
#===============================================================================

#other ideas:
#display:
# temperature
# load
# output volume
#
#change:
# audio volume

#need to check:
#DateTime object (again)
#timer interrupt (Time::HiRes e.g.)

#TODO:
#keep track of display (hour/min/sec)
#check every second/100ms if output changes or just output current value
#indicate current output state (show 1/2/3 on change for a moment)
#add display of date

use Modern::Perl 2013;
use warnings;

use MyPiFace;
use IO::Async::Channel;
use IO::Async::Loop;
use IO::Async::Routine;
use IO::Async::Timer::Periodic; 
use Time::HiRes qw(sleep usleep);

#TODO:
#use sensible values of DateTime structure or hash for mapping
#
#0 - hour
#1 - minute
#2 - second
my $state = 0;

my $out_ch1  = IO::Async::Channel->new;
my $in_ch2 = IO::Async::Channel->new;

my $piface = MyPiFace->new;

my $loop = IO::Async::Loop->new;

create_and_add_notifiers($loop);
say "Ready...";
$loop->run;

###########################################

sub start {
    say "Initializing PiFace...";
    $piface->init;
}

sub finish {
    $piface->deinit;
    $loop->stop;
    say "Goodbye!";
}

sub create_and_add_notifiers {
    my $loop = shift;
    create_input_routine($loop);
    create_output_routine($loop);
    create_timer($loop);
}
sub create_timer {
    my $loop = shift;
    my $timer = IO::Async::Timer::Periodic->new(
        interval => 1,
        first_interval => 1,
        on_tick => sub { handle_tick(); },
    );
    $loop->add( $timer );
}

sub create_input_routine {
    my $loop = shift;

    my $input_routine = IO::Async::Routine->new(
        channels_out => [ $out_ch1 ],

        code => sub {
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
    $loop->add( $input_routine );

    $out_ch1->configure(
        on_recv => sub {
            my ( $ch, $refout ) = @_;
            if(defined $refout->{'input'} && defined $refout->{'last_input'}) {
                my $input = $refout->{'input'};
                my $last_input =  $refout->{'last_input'};
                handle_input($input, $last_input);
            }
        }
    );
}

sub create_output_routine {
    my $loop = shift;

    my $output_routine = IO::Async::Routine->new(
        channels_in  => [ $in_ch2 ],
        channels_out => [ $out_ch2 ],

        code => sub {
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
    $loop->add( $output_routine );
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
        $state = ($state + 1) % 3;
    } elsif ($button == 1) { 
        $state = ($state - 1) % 3;
    } elsif (button == 2) {
        $state = 0;
    } elsif ($button == 3) { 
        say "exit.";
        finish();
    };
}

#react on timer interrupt
sub handle_tick {
    #send part of time instead
    my $time = time() % 256;
    $in_ch2->send( \$time );
}
