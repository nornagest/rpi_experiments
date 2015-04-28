#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: rrd_uploader.pl
#
#        USAGE: ./rrd_uploader.pl  
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
my $rsync_source = "/usr/share/nginx/rrd/";
my $rsync_dest = "nornagest\@nornagest.org:/usr/share/images/rrd/";
my $rsync_command = "rsync -r --remove-source-files";
my @imgs;
my $count;

while(1) {
    upload_files() if check_files() && scalar @imgs == $count;
    sleep(5);
}

sub check_files {
    $count = scalar @imgs;
    @imgs = ();
    sleep(5);
    find(\&wanted, $rsync_source);
    return scalar @imgs;
}

sub wanted {
    /.*\.png/ && !/lastsnap\.jpg/ && push @imgs, $_;
}

sub upload_files {
    my $command = $rsync_command . " " . $rsync_source . "* " . $rsync_dest;

    say scalar localtime . " Starting upload of " . $count . " files...";
    system($command);
    say scalar localtime . " Done.";
    
    sleep(60);
}

