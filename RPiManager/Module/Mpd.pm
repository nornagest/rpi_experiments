#
#===============================================================================
#
# FILE: Mpd.pm
#
# DESCRIPTION:
#
# FILES: ---
# BUGS: ---
# NOTES: ---
# AUTHOR: YOUR NAME (),
# ORGANIZATION:
# VERSION: 1.0
# CREATED: 01/29/2014 08:47:30 PM
# REVISION: ---
#===============================================================================

package Module::Mpd;

use Modern::Perl 2013;
use Moose;
extends 'Module';

use Message::Output;
use Net::MPD;
use Notifier::Timer;

has '+Name' => ( is => 'ro', isa => 'Str', default => 'MPD' );
has '+__direction' => ( default => 'Input' );
has '+__type'      => ( default => 'byte' );

has 'Host'     => ( is => 'rw', isa => 'Str', default => 'localhost' );
has 'Port'     => ( is => 'rw', isa => 'Int', default => 6600 );
has 'Password' => ( is => 'rw', isa => 'Str', default => '' );

has '__mpd'         => ( is => 'rw', isa => 'Net::MPD' );
has '__state'       => ( is => 'rw', isa => 'Str', default => '' );
has '__input_state' => ( is => 'rw', isa => 'Int', default => 0 );
has '__song'        => ( is => 'rw', isa => 'Str', default => '' );
has '__volume'      => ( is => 'rw', isa => 'Int', default => 0 );

sub BUILD {
    my $self = shift;
    my $timer =
      Notifier::Timer::create_timer_periodic( 1, 1, sub { $self->ping } );
    $self->Manager->add($self);
    $self->Manager->Loop->add($timer);
    $self->connect;
}

sub connect {
    my $self = shift;
    my $connect_string =
      $self->Password . '@' . $self->Host . ':' . $self->Port;
    $self->__mpd( Net::MPD->connect($connect_string) );
}

override 'send' => sub {
    my ( $self, $input ) = @_;
    return unless $self->accepts($input);
    my $byte = $input->Content->{byte} if defined $input->Content->{byte};
    $self->handle_input($byte) if defined $byte;
};

sub ping {
    my $self = shift;
    $self->__mpd->ping;

    my $status    = $self->__mpd->update_status;
    my $state     = $status->{"state"};
    my $volume    = $status->{"volume"};
    my $song_info = $self->__mpd->current_song;
    my $song      = $song_info->{"Name"};

    if (   ( defined $song && $song ne $self->__song )
        || $state ne $self->__state
        || $volume != $self->__volume )
    {
        $self->__song($song) if defined $song;
        $self->__state($state);
        $self->__volume($volume);
        $self->print_state;
    }
}

sub handle_input {
    my ( $self, $byte ) = @_;
    if ( $byte == 1 ) {
        if ( $self->__state eq 'play' ) {
            $self->stop;
        }
        else {
            $self->play;
        }
    }
    elsif ( $byte == 2 ) {
        $self->prev;
    }
    elsif ( $byte == 4 ) {
        $self->next;
    }
    elsif ( $byte == 16 ) {
        $self->vol_down;
    }
    elsif ( $byte == 32 ) {
        $self->vol_up;
    }
}

sub play {
    my $self = shift;
    return if $self->__state eq 'play';
    $self->__mpd->play;
}

sub stop {
    my $self = shift;
    $self->__mpd->stop;
}

sub next {
    my $self = shift;
    $self->__mpd->next;
}

sub prev {
    my $self = shift;
    $self->__mpd->previous;
}

sub vol_up {
    my $self   = shift;
    my $status = $self->__mpd->update_status;
    my $vol    = $status->{"volume"};
    $self->__mpd->volume( $vol + 3 );
}

sub vol_down {
    my $self   = shift;
    my $status = $self->__mpd->update_status;
    my $vol    = $status->{"volume"};
    $self->__mpd->volume( $vol - 3 );
}

sub print_state {
    my $self = shift;
    my $output =
        $self->__state
      . ' Song: '
      . $self->__song
      . ' Volume: '
      . $self->__volume;
    my $message = Message::Output->new(
        'Source'  => $self->Name,
        'Content' => { 'string' => $output },
    );
    $self->Manager->send($message);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
