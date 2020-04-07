#!/usr/bin/perl
#require 5.008;
{ package NES::RomTool;
  our $VERSION = "0.08"; # Time-stamp: <2017-04-28T07:58:07Z>
}

use strict;
use warnings;
#no autovivification qw(strict warn fetch exists delete store);
use utf8; # Japanese English

{
  package NES::RomTool;
  use base qw(JRF::Dummy);

  use POSIX qw(ceil);

  __PACKAGE__->extend_template
    (
     rom => undef,
     label => {},
    );

  sub read {
    my $self = shift;
    my ($addr, $size) = @_;
    $addr = $self->{label}->{$addr}if exists $self->{label}->{$addr};
    return substr($self->{rom}, $addr, $size);
  }

  sub replace {
    my $self = shift;
    my ($addr, $size, $replace) = @_;
    $addr = $self->{label}->{$addr}if exists $self->{label}->{$addr};
    my $prev = substr($self->{rom}, $addr, $size);
    substr($self->{rom}, $addr, $size) = $replace;
  }

  sub replace_chr_page {
    my $self = shift;
    my $rom = $self->{rom};
    my ($page, $replace) = @_;
    if (ref $replace) {
      # Future Work!
    }
    $replace .= "\x00" x (0x1000 - length($replace));
    $replace = substr($replace, 0, 0x1000);
    my $header = substr($rom, 0, 0x10);
    my ($magic, $prg_page, $chr_page, $ines_flags, $sys_flags,
	$ram_page, $tv_flags, $hd_flags) = unpack("a4CCCCCCC", $header);
      my ($mapper, $four_screen, $trainer, $sram, $vertical_mirror)
	= unpack_bits("B4BBBB", $ines_flags);
    if ($page >= $chr_page * 2) {
      my $new_size = ceil($page / 2);
      my $pre = substr($rom, 0x10, $trainer * 512 + $prg_page * 0x4000);
      my $chrrom = substr($rom,
			  0x10 + $trainer * 512 + $prg_page * 0x4000,
			  $chr_page * 0x2000);
      my $rest = substr($rom, 0x10 + $trainer * 512 + $prg_page * 0x4000
			+ $chr_page * 0x2000);
      my $newchrrom = "\x00" x ($new_size * 0x2000);
      substr($newchrrom, 0, $chr_page * 0x2000) = $chrrom;
      substr($newchrrom, $page * 0x1000, 0x1000) = $replace;
      $chr_page = $new_size;
      $header = pack("a4CCCCCCC", 
		     $magic, $prg_page, $chr_page, $ines_flags, $sys_flags,
		     $ram_page, $tv_flags, $hd_flags);
       $rom = $header . $pre . $newchrrom . $rest;
    } else {
      substr($rom, 0x10 + $trainer * 512 + $prg_page * 0x4000 
	     + $page * 0x1000, 0x1000) = $replace;
    }
    $self->{rom} = $rom;
  }

  sub new {
    my $class = shift;
    my $obj =  $class->SUPER::new(@_);
    my ($rom) = @_;
    $obj->{rom} = $rom;
    return $obj;
  }
}

1;
