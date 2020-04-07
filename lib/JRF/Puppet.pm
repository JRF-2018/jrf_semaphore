#!/usr/bin/perl
#require 5.008;
{ package JRF::Puppet;
  our $VERSION = "0.08"; # Time-stamp: <2017-04-28T07:19:27Z>
}

use strict;
use warnings;
#no autovivification qw(strict warn fetch exists delete store);
use utf8; # Japanese English

{
  package JRF::Puppet;
  use base qw(JRF::MyOO);

  use Storable qw(dclone);

  sub gene { return (); }

  sub clone {
    my $self = shift;
    my %gene = $self->gene();
    my $obj = (ref $self)->new(%gene);
    foreach my $k (keys %{(ref $self)->get_template()}) {
      if (! exists $gene{$k}) {
	if ((ref $self->{$k}) && defined &{(ref $self->{$k}) . "::clone"}) {
	  $obj->{$k} = $self->{$k}->clone();
	} else {
	  $obj->{$k} = dclone($self->{$k});
	}
      }
    }
    return $obj;
  }
}

1;
