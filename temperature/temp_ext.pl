#!/usr/bin/perl

use Modern::Perl 2013;
use File::Slurp;

my $dir = '/sys/bus/w1/devices';

load_modules() unless (-e $dir);
my @devices = read_devices($dir);

for my $dev (@devices) {
  if( $dev =~ m/28.*/ ) {
    my $file = $dir . '/' . $dev . '/w1_slave';
    my $temp = read_file($file);
    $temp =~ s/(.*YES.*\n.*t\=)(\d+)(\d{3})/$2\.$3°C/;
    print "Temperature ($dev): $temp";
  }
}

sub load_modules {
  system("modprobe", "w1-gpio") == 0
    or die "Could not load module w1-gpio.\n";
  system("modprobe", "w1-therm") == 0
    or die "Could not load module w1-therm.\n";
};

sub read_devices {
  my $dir = shift;
  opendir(my $dh, $dir) or die "Error opening $dir.\n";
  my @devices = readdir($dh);
  closedir($dh);
  return @devices;
}
