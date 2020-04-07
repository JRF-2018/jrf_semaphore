#!/usr/bin/perl
#require 5.008;
our $VERSION = "0.08"; #Time-stamp: <2017-04-28T12:24:01Z>

use strict;
use warnings;
use utf8; # Japanese

use File::Spec::Functions qw(catfile splitpath splitdir);

our $VERSIONS = "versions.txt";

use Getopt::Long;
#Getopt::Long::Configure("bundling", "no_ignore_case", "auto_version");
Getopt::Long::Configure("no_ignore_case", "auto_version");
GetOptions(
	   "help|h" => sub { usage(0); },
	  );

sub usage {
  my ($ext) = @_ || 0;
  print <<"EOU";
Usage: $0 PRG1 PRG2 ...
EOU
  exit($ext);
}

if (@ARGV == 0) {
  usage(1);
}

MAIN:
{
  my %version;
  if (-f $VERSIONS) {
    open(my $fh, "<", $VERSIONS) or die "$VERSIONS: $!";
    binmode($fh, ":utf8");
    while (my $s = <$fh>) {
      $s =~ s/[\r\n]+$//s;
      my ($prg, $ver, $tm) = split(/\s+/, $s, 3);
      if (! defined $tm) {
	die "$VERSIONS: Parse Error";
      }
      $version{$prg} = [$ver, $tm];
    }
  }
  my $err = 0;
  my $wr = 0;
  while (@ARGV) {
    my $src = shift(@ARGV);
    my ($v, $d, $f) = splitpath($src);
    my $base = $f;
    $base =~ s/\..*$//;
    $base = uc($base);
    open(my $fh, "<", $src) or die "$src: $!";
    binmode($fh, ":utf8");
    my ($tm, $ver);
    while (my $s = <$fh>) {
      $s =~ s/[\r\n]+$//s;
      if ($s =~ /Time-stamp:\s+[<\"]([^"]*)[\">]/i) {
	$tm = $1;
      }
      if ($s =~ /\Q$base\E_VER(?:SION)?\$?\s*=\s*\"?([^\s\"\']+)/i) {
	$ver = $1;
      }
      if ($s =~ /VER(?:SION)?_\Q$base\E\$?\s*=\s*\"?([^\s\"\']+)/i) {
	$ver = $1;
      }
      if ($s =~ /(?:^|[\s\$\{_])VERSION[\$\}]?\s*=\s*\"([^\s\"\;]*)/i) {
	$ver = $1;
      }
      if ($s =~ /(?:^|[\s\$\{_])VERSION[\$\}]?\s*=\s*([01-9]+(?:\.[01-9]+)?)/i) {
	$ver = $1;
      }
      if ($s =~ /(?:^|\S*_)VERSION\s+\.macro/i) {
	my $n = <$fh>;
	if ($n =~ /\"([^\s\"]+)/) {
	  $ver = $1;
	}
      }
      if ($s =~ /<\s*meta\s+name\s*=\s*\"version\"\s+content\s*=\s*\"([^\s\"]+)/i) {
	$ver = $1;
      }
      if (defined $tm && defined $ver) {
	last;
      }
    }
    close($fh);
    if (! defined $tm || ! defined $ver) {
      warn "$src: No ${base}_VER or Time-stamp.\n";
      $err = 1;
      next;
    }
    if (! exists $version{$src}) {
      warn "$src is NEW.\n";
      $version{$src} = [$ver, $tm];
      $wr = 1;
    } else {
      my ($prev_ver, $prev_tm) = @{$version{$src}};
      if ($prev_tm eq $tm) {
	if ($prev_ver ne $ver) {
	  warn "$src: Time-stamp should be updated.\n";
	  $err = 1;
	}
      } else {
	if ($prev_ver eq $ver) {
	  warn "$src: Version should be updated.\n";
	  $err = 1;
	} else {
	  $version{$src} = [$ver, $tm];
	  $wr = 1;
	}
      }
    }
  }
  if ($err) {
    exit(1);
  }
  if ($wr) {
    if (-f $VERSIONS) {
      rename($VERSIONS, $VERSIONS . "~") or die "$VERSIONS: $!";
    }
    open(my $fh, ">", $VERSIONS) or die "$VERSIONS: $!";
    binmode($fh, ":utf8");
    foreach my $src (sort (keys %version)) {
      my ($ver, $tm) = @{$version{$src}};
      print $fh "$src $ver $tm\n";
    }
    close($fh);
  }
  exit(0);
}
