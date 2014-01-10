#!/usr/bin/perl 
#===============================================================================
#
#         FILE: buttons_io_async.pl
#
#        USAGE: ./buttons_io_async.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hagen Kuehl
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
#
# Create PiFace
# Create Loop
# Create Notifiers and stuff
# Start Loop
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
# Check services regularly
# play/stop on time
#
#Stream/Socket
# for inputs via web interface or keyboard
#
#TODO:
#clean up on exit
#refactoring
#extract creation of notifiers, make classes if useful
#handle keeping state more sensible
#manage Channels more sensible
#add more stuff (signals, stream input, services/programs/commands to start)


#global state in this case for counter on LEDs
my $state = 0;
my $in_ch1 = IO::Async::Channel->new;
my $out_ch1  = IO::Async::Channel->new;
my $in_ch2 = IO::Async::Channel->new;
my $out_ch2  = IO::Async::Channel->new;

my $piface = MyPiFace->new;

my $loop = IO::Async::Loop->new;

create_and_add_notifiers($loop);
say "Ready...";
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

sub create_and_add_notifiers {
    my $loop = shift;
    create_input_routine($loop);
    create_output_routine($loop);
}

sub create_input_routine {
    my $loop = shift;

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
    $loop->add( $input_routine );

    $out_ch1->configure(
        on_recv => sub {
            my ( $ch, $refout ) = @_;
            say "Input routine says: ", $refout->{'text'}
            if(defined $refout->{'text'});
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
    $loop->add( $output_routine );

    $out_ch2->configure(
        on_recv => sub {
            my ( $ch, $output ) = @_;
            say "Output routine says: $$output";
        }
    );
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
        $state = ($state + 1) % 256;
        say "+1 ($state)";
    } elsif ($button == 1) { 
        $state = ($state - 1) % 256;
        say "-1 ($state)";
    } elsif ($button == 2) { 
        $state = 0;
        say "reset. ($state)";
    } elsif ($button == 3) { 
        say "exit.";
        finish();
    };

    $in_ch2->send( \$state );
}

