#!/usr/bin/perl
#require 5.008;
{ package JRF::Dummy;
  our $VERSION = "0.08"; # Time-stamp: <2017-04-28T07:18:28Z>
}

use strict;
use warnings;
#no autovivification qw(strict warn fetch exists delete store);
use utf8; # Japanese English

{
  package JRF::Dummy;
  use base qw(JRF::MyOO);

  use Storable qw(dclone);

  sub meme {
    # As getter (without arguments),
    # with class, return "meme" i.e. information needed for the class,
    # with object, return the meme of the object.
    # As setter or filter (with some arguments),
    # with class, filter arguments to rest meme needed for the class,
    # with object, set meme needed for the object.
    if (ref $_[0]) {
      my $proto = shift;
      if (@_) {
	my $head = (@_ % 2 == 1)? shift : undef;
	my %opt = @_;
	my %ref = (ref $proto)->meme(%$proto);
	my %r;
	foreach my $k (keys %opt) {
	  $proto->{$k} = $opt{$k} if ! exists $ref{$k};
	  $r{$k} = $opt{$k} if exists $ref{$k};
	}
	return %r;
      } else {
	my $self = $proto;
	my %ref = (ref $self)->meme(%$self);
	my %r;
	foreach my $k (keys %$self) {
	  if (! exists $ref{$k}) {
	    $r{$k} = $self->{$k};
	  }
	}
	return %r;
      }
    } else {
      my $class = shift;
      if (@_) {
	my $head = (@_ % 2 == 1)? shift : undef;
	my @tmp = $class->meme();
	my $thead = (@tmp % 2 == 1)? shift(@tmp) : undef;
	if (defined $thead && defined $head) {
	  unshift(@tmp, $head);
	  unshift(@tmp, $thead);
	}
	my %tmp = @tmp;
	my %opt = @_;
	my %r;
	foreach my $k (keys %opt) {
	  $r{$k} = $opt{$k} if exists $tmp{$k};
	}
	return %r;
      } else {
	my %r = %{$class->get_template()};
	delete $r{cvar};
	return %r;
      }
    }
  }

  sub clone {
    my $self = shift;
    my @meme = $self->meme();
    $self = bless dclone({(ref $self)->meme(%$self)}), (ref $self);
    $self->meme(@meme);
    return $self;
  }
}

1;
