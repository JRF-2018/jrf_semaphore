#!/usr/bin/perl
#require 5.008;
{ package GifFont::JRFSemaphoreRom;
  our $VERSION = "0.08"; # Time-stamp: <2017-04-28T08:11:47Z>
}

use strict;
use warnings;
#no autovivification qw(strict warn fetch exists delete store);
use utf8; # Japanese English

{
  package GifFont::JRFSemaphoreRom;
  use base qw(GifFont);

  use GD;
  use Carp;

  use NES::ChrPage;
  use JRF::FlagSemaphore;

  __PACKAGE__->extend_template
    (
     page => 0,
     palette => 0,
     chr_page => undef,
    );

  sub get_true_color {
    my $self = shift;
    my ($c) = @_;
    return @$c if ref $c;
    return $self->{chr_page}->nes_true_color($c);
  }

  sub get_cmap {
    my $self = shift;
    return $self->{gd} if defined $self->{gd};

    my @pal;
    if (ref $self->{palette}) {
      @pal = @{$self->{palette}};
    } else {
      push(@pal, $self->{palette});
    }
    $self->{chr_page}->gd_page($self->{page}, @pal);
    $self->{gd} = $self->{chr_page}->get_gd();
    return $self->{gd};
  }

  sub new {
    my $class = shift;
    my $self =  $class->SUPER::new(@_);
    my %opt = %{$self->{orig_opt}};
    if (exists $opt{file}) {
      $self->{chr_page} = NES::ChrPage->new($opt{file});
    } else {
      $self->{chr_page} = JRF::FlagSemaphore->get_cvar()->{CHR_PAGE};
    }
    if (exists $opt{nes}) {
      $self->{page} = $opt{nes};
    }
    if (exists $opt{palette}) {
      if ($opt{palette} =~ /,/) {
	$self->{palette} = [split(/\s*,\s*/, $opt{palette})];
      } else {
	$self->{palette} = $opt{palette};
      }
    }
    return $self;
  }
}

1;
