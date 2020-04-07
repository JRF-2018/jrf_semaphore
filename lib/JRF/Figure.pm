#!/usr/bin/perl
#require 5.008;
{ package JRF::Figure;
  our $VERSION = "0.08"; # Time-stamp: <2017-04-28T07:52:33Z>
}

use strict;
use warnings;
#no autovivification qw(strict warn fetch exists delete store);
use utf8; # Japanese English

{
  package JRF::Figure; # with brain, no requirement for spirit.
  use base qw(JRF::Puppet JRF::Dummy);

  use Carp;

  $JRF::MyOO::CVAR_DEBUG = 1;

  __PACKAGE__->extend_cvar
    (
     PUBLIC_true => "1",  # <- an example garbage.
    );

  sub brain {} # set brain.
  sub super_brain {  # brain of super class.
    if (ref $_[0]) {
      my $self = shift;
      return undef;
    } else {
      my $class = shift;
      my ($brain) = @_;
      return undef;
    }
  }

  sub gene {
    if (ref $_[0]) {
      my $self = shift;
      return %$self;
    } else {
      my $class = shift;
      return %{$class->get_template()};
    }
  }

  sub meme {
    if (! ref $_[0]) {
      my $class = shift;
      if (@_) {
	my $odd = (@_ % 2 == 1);
	my $head = ($odd)? shift : undef;
	my @r = $class->SUPER::meme(@_);
	unshift(@r, $head) if $odd;
	return @r;
      }
      my @gene = $class->gene();
      my $odd = (@gene % 2 == 1);
      my $head = ($odd)? shift(@gene) : undef;
      unshift(@_, $head) if defined $head;
      my %opt = @gene;
      my %ref = $class->SUPER::meme();
      my %r;
      foreach my $k (keys %ref) {
	$r{$k} = $opt{$k} if exists $ref{$k};
      }
      my $cvar = $class->get_cvar();
      foreach my $k (keys %$cvar) {
	if ($k =~ /^PUBLIC_/) {
	  my $n = $&;
	  my $v = $cvar->{$k};
	  $r{$n} = $v if ! exists $r{$n};
	}
      }
      my @r = %r;
      unshift(@r, $head) if $odd;
      return @r;
    } else {
      my $dummy = shift;
      return $dummy->SUPER::meme() if ! @_;
      my $head = (@_ % 2 == 1)? shift(@_) : undef;
      $dummy->brain($head);
      return $dummy->SUPER::meme(@_);
    }
  }

  sub clone {
    my $self = shift;
    my @meme = $self->meme();
    my @gene = $self->gene();
    my $obj = (ref $self)->new((ref $self)->meme(@gene));
    $obj->meme(@meme);
    return $obj;
  }

  sub add_cvar_hook {
    my $self = shift;
    my ($name, @rest) = @_;
    if ($name !~ /^PUBLIC_/) {
      if ($main::DEBUG) {
	carp "add_cvar_hook: is not allowed for $name.";
      } else {
	croak "add_cvar_hook: is not allowed for $name.";
      }
    }
    $self->SUPER::add_cvar_hook($name, @rest);
  }

  sub remove_cvar_hook {
    my $self = shift;
    my ($name, @rest) = @_;
    if ($name !~ /^PUBLIC_/) {
      if ($main::DEBUG) {
	carp "remove_cvar_hook: is not allowed for $name.";
      } else {
	croak "remove_cvar_hook: is not allowed for $name.";
      }
    }
    $self->SUPER::remove_cvar_hook($name, @rest);
  }

  sub new {
    my $class = shift;
    my $brain = (@_ % 2 == 1)? shift : undef;
    my %opt = @_;
    my $cdb = $JRF::MyOO::CVAR_DEBUG;
    $JRF::MyOO::CVAR_DEBUG = 1;

    my $sbrain;
    $sbrain = $class->super_brain($brain) if defined $brain;
    unshift(@_, $sbrain) if defined $sbrain;
    my $obj = $class->SUPER::new(@_);
    my %smeme = (map {($_->can('meme'))? $_->meme() : ()}
		 (eval '@{' . $class . '::ISA}'));
    my %meme = $class->meme();
    foreach my $k (keys %opt) {
      if (exists $meme{$k} && ! exists $smeme{$k}) {
	$obj->{$k} = $opt{$k};
      }
    }
    $obj->meme($brain);

    $JRF::MyOO::CVAR_DEBUG = $cdb;
    return $obj;
  }
}

1;
