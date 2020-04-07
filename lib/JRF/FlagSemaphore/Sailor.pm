#!/usr/bin/perl
#require 5.008;
{ package JRF::FlagSemaphore::Sailor;
  our $VERSION = "0.08"; # Time-stamp: <2017-04-28T08:05:59Z>
}

use strict;
use warnings;
#no autovivification qw(strict warn fetch exists delete store);
use utf8; # Japanese English

{
  package JRF::FlagSemaphore::Sailor;
  use base qw(JRF::MyOO);

  use GD;

  __PACKAGE__->extend_template
    (
     j => undef,
     font => 1,
     bg => undef,
     spr => undef,
     spw => undef,
     sprh => undef,
     spwh => undef,
     bgcolor => undef,
     size => [48, 48],
     center => [24, 32],
    );

  sub new {
    my $class = shift;
    my ($j, %opt) = @_;
    my $obj =  $class->SUPER::new(@_);
    $obj->{j} = $j;
    my $cp = $j->{cvar}->{CHR_PAGE};
    my @c;
    if (exists $opt{color}) {
      if (ref $opt{color}) {
	@c = @{$opt{color}};
      } else {
	@c = $cp->palette_colors($opt{color});
      }
    }
    @c = $cp->palette_colors(1) if ! @c;
    $cp->gd_page(0, @c);
    $obj->{bg} = $cp->{gd}->clone();
    my @sc = $cp->palette_colors(5);
    $sc[3] = $c[3];
    $cp->change_color(@sc);
    $obj->{spw} = $cp->{gd}->clone();
    $obj->{spwh} = $obj->{spw}->clone();
    $obj->{spwh}->flipHorizontal();
    @sc = $cp->palette_colors(7);
    $sc[3] = $c[3];
    $cp->change_color(@sc);
    $obj->{spr} = $cp->{gd}->clone();
    $obj->{sprh} = $obj->{spr}->clone();
    $obj->{sprh}->flipHorizontal();

    $obj->{bg}->transparent(0);
    $obj->{spw}->transparent(0);
    $obj->{spwh}->transparent(0);
    $obj->{spr}->transparent(0);
    $obj->{sprh}->transparent(0);

    if (exists $opt{font}) {
      my $f = $opt{font};
      if ($f =~ /^[01-9]+$/) {
	$obj->{font} = $f & 7;
      } else {
	my $n = 0;
	if ($f =~ /italic/i) {
	  $n = $n | 1;
	}
	if ($f =~ /slant/i) {
	  $n = $n | 2;
	}
	if ($f =~ /bold/i) {
	  $n = $n | 4;
	}
	$obj->{font} = $n;
      }
    }

    my $bg;
    if (exists $opt{bgcolor}) {
      $bg = $opt{bgcolor};
      if (! ref $bg) {
	$bg = [$cp->nes_true_color($bg)];
      }
    }
    if (! defined $bg || @$bg < 3) {
      $bg = [$cp->nes_true_color(($cp->palette_colors(4))[0])];
    }
    $obj->{bgcolor} = $bg;

    return $obj;
  }

  sub _draw_chr {
    my $self = shift;
    my ($dest, $src, $srch, $spec, $x, $y) = @_;
    my ($col, @chr) = @$spec;
    if ($col & 0x40) {
      @chr = map {16 * int($_ / 16) + 15 - ($_ % 16)} @chr;
      $src = $srch;
    }
    my $c = $chr[0];
    $dest->copy($src, $x, $y, 8 * ($c % 16), 8 * int($c / 16), 8, 8);
    $c = $chr[1];
    $dest->copy($src, $x + 8, $y, 8 * ($c % 16), 8 * int($c / 16), 8, 8);
    $c = $chr[2];
    $dest->copy($src, $x, $y + 8, 8 * ($c % 16), 8 * int($c / 16), 8, 8);
    $c = $chr[3];
    $dest->copy($src, $x + 8, $y + 8, 8 * ($c % 16), 8 * int($c / 16), 8, 8);
  }

  sub flag {
    my $self = shift;
    my ($c) = @_;
    my $sailor_chr = $self->{j}->{cvar}->{SAILOR_CHR};
    my $flag_chr = $self->{j}->{cvar}->{FLAG_CHR};
    my $flag_loc = $self->{j}->{cvar}->{FLAG_LOC};
    my $sfont = $self->{font} >> 1;
    my $ffont = $self->{font} & 1;
    my $gd = GD::Image->new(@{$self->{size}});
    $gd->colorAllocate(@{$self->{bgcolor}});
    $gd->filledRectangle(0, 0, @{$self->{size}}, 0);
    my ($bx, $by) = @{$self->{center}};
    $bx -= 8;
    $by -= 16;
    my $lred = (ord($c) >> 4) & 0x7;
    my $rwhite = ord($c) & 0x7;
    my ($lx, $ly) = @{$flag_loc->[$lred]};
    my ($rx, $ry) = @{$flag_loc->[8 + $rwhite]};

    $self->_draw_chr($gd, $self->{bg}, $self->{bg},
		     $sailor_chr->[$sfont * 2], $bx, $by);
    $self->_draw_chr($gd, $self->{bg}, $self->{bg},
		     $sailor_chr->[$sfont * 2 + 1], $bx, $by + 16);
    if ($rwhite > $lred) {
      $self->_draw_chr($gd, $self->{spr}, $self->{sprh},
		       $flag_chr->[$ffont * 16 + $lred],
		       $bx + $lx, $by + $ly);
      $self->_draw_chr($gd, $self->{spw}, $self->{spwh},
		       $flag_chr->[$ffont * 16 + 8 + $rwhite],
		       $bx + $rx, $by + $ry);
    } else {
      $self->_draw_chr($gd, $self->{spw}, $self->{spwh},
		       $flag_chr->[$ffont * 16 + 8 + $rwhite],
		       $bx + $rx, $by + $ry);
      $self->_draw_chr($gd, $self->{spr}, $self->{sprh},
		       $flag_chr->[$ffont * 16 + $lred],
		       $bx + $lx, $by + $ly);
    }
    return $gd;
  }

  sub flag_gif {
    my $self = shift;
    my ($s, %opt) = @_;
    my $bg;
    $bg = $opt{bgcolor} if exists $opt{bgcolor};
    $bg = $opt{bg} if exists $opt{bg};
    my ($w, $h) = @{$self->{size}};
    my ($bx, $by) = (0, 0);
    if (exists $opt{center}) {
      ($bx, $by) = @{$opt{center}};
      $bx = int($bx - $w * 0.5);
      $by = int($by - $h * 0.5);
    }
    if (exists $opt{size}) {
      ($w, $h) = @{$opt{size}};
    }
    $w = $opt{width} if exists $opt{width};
    $h = $opt{height} if exists $opt{height};
    $bg = $self->{bgcolor} if ! defined $bg;
    if (defined $bg && ! ref $bg) {
      $bg = [$self->{j}->{CHR_PAGE}->nes_true_color($bg)];
    }
    if ('ARRAY' eq (ref $bg)) {
      my $gd = GD::Image->new($w, $h);
      $gd->colorAllocate(@$bg);
      $gd->filledRectangle(0, 0, $w, $h, 0);
      $bg = $gd;
    }
    my $loop = 0;
    $loop = $opt{loop} if exists $opt{loop};
    my $interval = 100;
    $interval = $opt{interval} if exists $opt{interval};
    my $gifanim;

    while ($s ne "") {
      my $c = substr($s, 0, 1);
      $s = substr($s, 1);
      my $gd = $self->flag($c);
      if (defined $bg) {
	$gd->transparent(0);
	my $gd2 = $bg->clone();
	$gd2->copy($gd, $bx, $by, 0, 0, $gd->width, $gd->height);
	$gd = $gd2;
      }
      if (! defined $gifanim) {
	return $gd->gif() if $s eq "";
	$gifanim = $gd->gifanimbegin(0, $loop);
      }
      $gifanim .= $gd->gifanimadd(1, 0, 0, $interval);
      $gifanim .= $gd->gifanimend() if $s eq "";
    }
    return $gifanim;
  }
}

1;
