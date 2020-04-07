#!/usr/bin/perl
#require 5.008;
{ package GifFont;
  our $VERSION = "0.08"; # Time-stamp: <2017-04-28T16:12:11Z>
}

use strict;
use warnings;
#no autovivification qw(strict warn fetch exists delete store);
use utf8; # Japanese English

{
  package Resource;

  our %COLOR_NAME_LC;

 ModuleInit:
  {
    if (! %COLOR_NAME_LC) {
      use GD::simple;

      my $cn = GD::Simple->color_names();
      foreach my $k (keys %$cn) {
	my $v = $cn->{$k};
	$COLOR_NAME_LC{lc($k)} = $v;
      }
    }
  }
}

{
  package GifFont;
  use base qw(JRF::MyOO);

  use GD;

  use JRF::Utils qw(:all);

  __PACKAGE__->extend_template
    (
     gd => undef,
     orig_opt => {},

     bgcolor => [0x10, 0x43, 0x1f],
     font_width => 8,
     font_height => 8,
     char_width => 8,
     line_height => 16,
     margin_top => 8,
     margin_left => 8,
     margin_bottom => 8,
     margin_right => 8,
     cols => 22,
     address_map => [],
     direction => "ltor",
     rotate => 0,
     first_point => [0, 0],
    );

#  __PACKAGE__->extend_cvar
#    (
#    );

  our %OPT_ABBREV
    = (
       s => "size",
       w => "font_width",
       h => "font_heigth",
       cw => "char_width",
       bg => "bgcolor",
       l => "line_height",
       lh => "line_height",
       m => "margin",
       a => "address",
       r => "rotate",
       d => "direction",
       pal => "palette",
       f => "first_point",
      );

  sub new {
    my $class = shift;
    my $self =  $class->SUPER::new(@_);
    my (@opt) = @_;
    my @addr;
    my %opt;
    if (@opt % 2) {
      $opt{file} = shift(@opt);
    }
    while (@opt) {
      my $k = shift(@opt);
      my $v = shift(@opt);
      my $key = $k;
      $key =~ s/^\-\-?//;
      $key =~ s/\-/_/g;
      $key = $OPT_ABBREV{$key} if exists $OPT_ABBREV{$key};
      if ($key eq "address") {
	push(@addr, $v);
      } else {
	$opt{$key} = $v;
      }
    }
    $self->{orig_opt} = \%opt;

    if (exists $opt{size}) {
      my ($w, $h);
      if (ref $opt{size}) {
	($w, $h) = @{$opt{size}};
      } else {
	($w, $h) = split("x", $opt{size});
      }
      $self->{font_width} = $w;
      $self->{font_height} = $h;
    }

    if (exists $opt{first_point}) {
      my ($x, $y);
      if (ref $opt{first_point}) {
	($x, $y) = @{$opt{first_point}};
      } else {
	($x, $y) = split(/\s*,\s*/, $opt{first_point});
      }
      $self->{frist_point} = [$x, $y];
    }

    if (exists $opt{margin}) {
      my ($top, $left, $bottom, $right) = split(/\s*,\s*/, $opt{margin});
      $top = 0 if ! defined $top;
      $left = $top if ! defined $left;
      $bottom = $top if ! defined $bottom;
      $right = $left if ! defined $right;
      $self->{margin_top} = $top;
      $self->{margin_left} = $left;
      $self->{margin_bottom} = $bottom;
      $self->{margin_right} = $right;
    }

    foreach my $k (qw(char_width line_height font_width 
		      font_height rotate direction gd)) {
      $self->{$k} = $opt{$k} if exists $opt{$k};
    }

    $self->{direction} = lc($self->{direction});
    $self->{direction} =~ s/right/r/g;
    $self->{direction} =~ s/left/l/g;
    $self->{direction} =~ s/\-//g;

    foreach my $addr (@addr) {
      my ($range, $map) = split(/\:/, $addr);
      if (! defined $map) {
	$map = "0-FF";
      }
      my ($from, $to) = map {parse_int($_, 16)} split(/\-/, $range);
      my ($mfrom, $mto) = map {parse_int($_, 16)} split(/\-/, $map);
      my ($hdir, $vdir) = (1, 1);
      if (defined $mto && ($mfrom eq "" 
			   || ($mto ne "" && ($mto - $mfrom) < 0))) {
	$hdir = -1;
	$vdir = -1;
      }
      $to = $from if ! defined $to;
      $to = undef if $to eq "";
      push(@{$self->{address_map}}, [$from, $to, $mfrom, $hdir, $vdir]);
    }

    return $self;
  }

  sub get_true_color {
    my $self = ((ref $_[0])->isa(__PACKAGE__))? shift : undef;
    my ($c) = @_;
    return @$c if ref $c;
    if (exists $Resource::COLOR_NAME_LC{lc($c)}) {
      return @{$Resource::COLOR_NAME_LC{lc($c)}};
    } else {
      return ();
    }
  }

  sub get_cmap {
    my $self = shift;
    return $self->{gd} if defined $self->{gd};
    if (exists $self->{orig_opt}->{file}) {
      $self->{gd} = GD::Image->new($self->{orig_opt}->{file});
    }
    return $self->{gd};
  }

  sub text_gd {
    my $self = shift;
    my ($s, %opt) = @_;
    my $cmap = $self->get_cmap();
    my @line;
    my $gd;
    my $col;
    my $x;
    my $row = 0;
    my $bgcolor = [$self->get_true_color($self->{bgcolor})];
    my @amap = @{$self->{address_map}};
    while ($s ne "") {
      my $c = substr($s, 0, 1);
      $s = substr($s, 1);
      my $o = ord($c);
      if (! defined $gd) {
	my $w = $self->{margin_left} + $self->{char_width} * $self->{cols}
	  + $self->{margin_right};
	my $h = $self->{line_height};
	$gd = GD::Image->new($w, $h);
	$gd->colorAllocate(@$bgcolor);
	$gd->filledRectangle(0, 0, $w, $h, 0);
	$gd->transparent(0);
	if ($self->{direction} eq "rtol") {
	  $x = $self->{margin_left} + $self->{char_width} * ($self->{cols} - 1);
	} else {
	  $x = $self->{margin_left};
	}
	$col = 0;
	$row++;
      }
      foreach my $p (@amap) {
	my ($from, $to, $mfrom, $hdir, $vdir) = @$p;
	next if $o < $from;
	next if defined $to && $o > $to;
	my $fx = $mfrom % 16;
	my $fy = int($mfrom / 16);
	my $dx = ($o - $from) % 16;
	my $dy = int(($o - $from) / 16);
	my $cx = $fx + $hdir * $dx;
	$dy += abs(int($cx / 16));
	$cx = $cx % 16;
	my $cy = $fy + $dy * $vdir;
	$o = $cx + $cy * 16;
      }

      if ($self->{font_width} * 2 <= $self->{font_height}) {
	if ($o & 0x80) {
	  $o = ($o + ($o & 0xf0)) | 0x10;
	  if ($o & 0x80) {
	    $o = ~$o;
	  }
	}
	$o = $o & 0x7F;
      } else {
	$o = $o & 0xFF;
      }
      my ($fx, $fy) = @{$self->{first_point}};
      $fx += ($o % 16) * $self->{font_width};
      $fy += $self->{font_height} * int($o / 16);
      $gd->copyRotated($cmap, $x + ($self->{char_width} / 2),
		       $self->{line_height} / 2, $fx, $fy,
		       $self->{font_width}, $self->{font_height},
		       $self->{rotate});
      if ($self->{direction} eq "rtol") {
	$x -= $self->{char_width};
      } else {
	$x += $self->{char_width};
      }
      $col++;
      if ($col >= $self->{cols}) {
	push(@line, $gd);
	$gd = undef;
      }
    }
    push(@line, $gd) if defined $gd;
    if (1) {
      my $w = $self->{margin_left} + $self->{char_width} * $self->{cols}
	+ $self->{margin_right};
      my $h = $self->{margin_top} + ($self->{line_height} * @line)
	+ $self->{margin_top};
      my $gd = GD::Image->new($w, $h);
      $gd->colorAllocate(@$bgcolor);
      $gd->filledRectangle(0, 0, $w, $h, 0);
      my $y = $self->{margin_top};
      foreach my $l (@line) {
	$gd->copy($l, 0, $y, 0, 0, $l->width, $l->height);
	$y += $l->height;
      }
      return $gd;
    }
  }
}

1;
