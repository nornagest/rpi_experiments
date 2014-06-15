#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: MotionUploader.pl
#
#        USAGE: ./MotionUploader.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hagen Kuehl (), nornagest[at]gmx.de
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 06/01/2014 03:10:40 PM
#     REVISION: ---
#===============================================================================

use Modern::Perl 2013;
use warnings;
use File::Find;
use Sys::Hostname;

my $host = hostname;
my $rsync_source = "/usr/share/motion/";
my $rsync_dest = "nornagest\@nornagest.org:/usr/share/images/" . $host;
my $rsync_command = "rsync -r --remove-source-files";
my @jpgs;

while(1) {
    upload_files() if check_files();
    sleep(1);
}

sub check_files {
    @jpgs = ();
    find(\&wanted, $rsync_source);
    return scalar @jpgs;
}

sub wanted {
    /.*\.jpg/ && !/lastsnap\.jpg/ && push @jpgs, $_;
}

sub upload_files {
    my $command = $rsync_command . " " . $rsync_source . "* " . $rsync_dest;

    #say scalar localtime . " Executing: $command";
    say scalar localtime . " Starting upload of " . scalar @jpgs . " files...";
    system($command);
    say scalar localtime . " Done.";
}

