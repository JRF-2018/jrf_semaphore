#!/usr/bin/perl
#require 5.008;
{ package NES::ChrPage;
  our $VERSION = "0.08"; # Time-stamp: <2017-04-28T09:59:39Z>
}

use strict;
use warnings;
#no autovivification qw(strict warn fetch exists delete store);
use utf8; # Japanese English

{
  package NES::ChrPage;
  use base qw(JRF::MyOO);

  use GD;
  use Carp;

  use JRF::Utils qw(:all);
#  use JRF::FlagSemaphore;

  #@NES_PAL from yychr.pal of YY-CHR.NET.
  our @NES_PAL = map {hex($_)} qw(
6b 6b 6b 00 10 84 08 00 8c 42 00 7b 63 00 5a 6b
00 10 60 00 00 4f 35 00 31 4e 18 00 5a 21 21 5a
10 08 52 42 00 39 73 00 00 00 00 00 00 00 00 00
a5 a5 a5 00 42 c6 42 29 ce 6b 00 bd 94 29 94 9c
10 42 9c 39 00 84 5e 21 5f 7b 21 2d 8c 29 18 8e
10 2e 86 63 29 73 9c 00 00 00 00 00 00 00 00 00
ef ef ef 5a 8c ff 7b 6b ff a5 5a ff d6 4a ff e7
63 9c de 7b 52 ce 9c 29 ad b5 31 7b ce 31 5a ce
52 4a c6 94 4a b5 ce 52 52 52 00 00 00 00 00 00
ef ef ef ad c6 ff bd bd ff ce b5 ff e7 b5 ff f9
bb df f7 c6 b5 de c6 9c d6 d6 94 c6 e7 9c b5 e7
ad ad e7 c6 ad de e7 ad ad ad 00 00 00 00 00 00
);

  __PACKAGE__->extend_template
    (
     chrrom => undef,
     palettes => [map {(0x00 + $_, 0x10 + $_, 0x20 + $_, 0x30 + $_)}
		  (0x0 .. 0xd)],
     pages => [],
     color => undef,
     gd => undef,
    );

  sub load_rom {
    my $self = shift;
    my ($rom) = @_;
    if ($rom !~ /^NES\x1a/) {
      my $basename = $rom;
      $basename = substr($basename, 0, 3)
	. "..." . substr($basename, -32) if length($basename) > 64;
      open(my $fh, "<", encode_fn($rom)) or croak "$basename: $!";
      binmode($fh, ":raw");
      $rom = join("", <$fh>);
      close($fh);
    }
    my $header = substr($rom, 0, 0x10);
    my ($magic, $prg_page, $chr_page, $ines_flags, $sys_flags,
	$ram_page, $tv_flags, $hd_flags) = unpack("a4CCCCCCC", $header);
    if ($magic ne "NES\x1a") {
      croak "Rom Parse Error.";
    }
    my ($mapper, $four_screen, $trainer, $sram, $vertical_mirror)
      = unpack_bits("B4BBBB", $ines_flags);
    # or # =  map {unpack("C", pack("b" . length($_), scalar reverse($_)))} unpack("a4aaaa", unpack("B8", pack("C", 0x43)))); # Crazy!
    $prg_page = $prg_page || 1;
    $chr_page = $chr_page || 1;
    $self->{chrrom} = substr($rom,
			     0x10 + $trainer * 512 + $prg_page * 0x4000,
			     $chr_page * 0x2000);
  }

  sub new {
    my $class = shift;
    my $obj =  $class->SUPER::new(@_);
    my ($rom, %opt) = @_;
    $obj->{palettes} = $opt{palettes} if exists $opt{palettes};
    $obj->load_rom($rom);
    return $obj;
  }

  sub nes_true_color {
    my $self = (ref $_[0])? shift : undef;
    my ($c) = @_;
    if ($c =~ /^[01-9]+/) {
      return  @NES_PAL[$c * 3, $c * 3 + 1, $c * 3 + 2];
    } elsif ($c =~ /^#([01-9A-Fa-f]{6})/) {
      return (hex(substr($1, 0, 2)),
	      hex(substr($1, 2, 2)),
	      hex(substr($1, 4, 2)));
    } else {
      if (exists $Resource::COLOR_NAME_LC{lc($c)}) {
	return @{$Resource::COLOR_NAME_LC{lc($c)}};
      } else {
	return ();
      }
    }
  }

  sub palette_colors {
    my $self = shift;
    my ($n) = @_;
    my $pal;
    $pal = $self->{palettes};
    my $i = $n * 4;
    return () if $i + 4 > @$pal;
    return @{$pal}[$i, $i + 1, $i + 2, $i + 3];
  }

  sub gd_page {
    my $self = shift;
    my ($num, @c) = @_;
    my $pages;
    my $rom;
    my $pal;
    $pages = $self->{pages};
    $rom = $self->{chrrom};
    $pal = $self->{palettes};
    return undef if length($rom) < ($num + 1) * 4096;
    if (defined $pages->[$num]) {
      $self->{gd} = $pages->[$num];
      $self->change_color(@c) if @c;
      return $self->{gd};
    }

    if (@c == 0) {
      if (defined $self->{color}) {
	@c = @{$self->{color}};
      } else {
	@c = $self->palette_colors(0);
      }
    }
    if (@c == 1) {
      my $i = $c[0] * 4;
      return undef if $i + 4 > @$pal;
      @c = @{$pal}[$i, $i + 1, $i + 2, $i + 3];
    }

    my $gd = GD::Image->new(128, 128, 0);
    for (my $i = 0; $i < @c; $i++) {
      my ($r, $g, $b) = nes_true_color($c[$i]);
      carp "$c[$i]: Illegal color name." if ! defined $r;
      my $id = $gd->colorAllocate($r, $g, $b);
    }
    $self->{color} = \@c;

    #$gd->transparent(0);
    for (my $i = 0; $i < 256; $i++) {
      my $addr = $num * 4096 + $i * 16;
      my $bx = ($i % 16) * 8;
      my $by = 8 * int($i / 16);
      for (my $y = 0; $y < 8; $y++) {
	my $l = ord(substr($rom, $addr + $y, 1));
	my $h = ord(substr($rom, $addr + $y + 8, 1));
	my $b = 0x80;
	for (my $x = 0; $x < 8; $x++, $b = $b >> 1) {
	  my $c = (!!($h & $b)) * 2 + (!!($l & $b));
	  $gd->setPixel($bx + $x, $by + $y, $c);
	}
      }
    }
    $pages->[$num] = $gd;
    $self->{gd} = $gd;

    return $gd;
  }

  sub get_gd {
    my $self = shift;
    my $gd = $self->{gd}->clone();
    $gd->transparent(0);
    return $gd;
  }

  sub change_color {
    my $self = ((ref $_[0])->isa(__PACKAGE__))? shift : undef;
    my $map = (defined $self)? $self->{gd} : shift;
    my (@c) = @_;
    carp "You can't change_color after setting GD::transparent()."
      if $map->transparent() != -1;
    if (@c == 1) {
      if (! defined $self) {
	require JRF::FlagSemaphore;
	$self = JRF::FlagSemaphore->get_cvar()->{CHR_PAGE};
      }
      @c = $self->palette_colors($c[0]);
    }
    for (my $i = 0; $i < @c; $i++) {
      $map->colorDeallocate($i);
      $map->colorAllocate(nes_true_color($c[$i]));
    }
    $self->{color} = \@c if defined $self;
    return $map;
  }
}

1;
