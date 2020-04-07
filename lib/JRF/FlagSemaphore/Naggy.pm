#!/usr/bin/perl
#require 5.008;
{ package JRF::FlagSemaphore::Naggy;
  our $VERSION = "0.08"; # Time-stamp: <2017-04-28T08:13:45Z>
}

use strict;
use warnings;
#no autovivification qw(strict warn fetch exists delete store);
use utf8; # Japanese English

{
  package JRF::FlagSemaphore::Naggy;
  use base qw(JRF::MyOO);

  use Carp;

  use JRF::Resource qw(locate_file_resource);

  __PACKAGE__->extend_template
    (
     jc => undef,
     initialized => 0,
     convert_init => "convert-init.nginit",
    );

  sub new {
    my $class = shift;
    my ($jc, %opt) = @_;
    my $obj =  $class->SUPER::new();
    $obj->{jc} = $jc;
    if (exists $opt{convert_init}) {
      $obj->{convert_init} = $opt{convert_init};
    }
    return $obj;
  }

  sub initialize {
    my $self = shift;
    return if $self->{initialized};

    my $JC = $self->{jc};
    if (! defined $JC->{ngb}) {
      $JC->init_naggy_backend();
      croak "Naggy::Backend: failed to invoke." if ! defined $JC->{ngb};
    }
    my $ngb = $JC->{ngb};
    my $fn = locate_file_resource($self->{convert_init});
    croak "$self->{convert_init}: Not found." if ! defined $fn;
    if (! $ngb->load_init_file($fn)) {
      croak "$self->{convert_init}: Initialization failed.  Maybe, some files not found.  Check convert-init.nginit .";
    }
    $self->{initialized} = 1;
  }

  sub encode { # alpha to naggy.
    my $self = shift;
    $self->initialize() if ! $self->{initialized};

    my ($s) = @_;
    my $ngb = $self->{jc}->{ngb};

    my $r = "";
    my $m = "";
    while ($s =~ /,|\s+/s) {
      my $c = $&;
      my $prev = $`;
      $s = $';
      if ($c ne ",") {
	$r .= $m . $prev . $c;
	$m = "";
	next;
      }
      if (length($s) > 0 && substr($s, 0, 1) eq ",") {
	$m = $m . $prev . ",";
	$s = substr($s, 1);
	next;
      }
      $m = $m . $prev;
      if ($s !~ /\.|\s+/s) {
	$r .= $m . $s;
	$m = "";
	last;
      }
      $c = $&;
      $prev = $`;
      $s = $';
      if ($c ne ".") {
	$r .= $m . "," . $prev . $c;
	$m = "";
	next;
      }
      my $name = $prev;
      $c = "";
      if ($prev =~ /,/) {
	$name = $`;
	$c = $& . $';
      }
      if (! exists $ngb->{convert}->{table}->{$name}) {
	$r .= $m . "," . $name . $c . ".";
	$m = "";
	warn "$name: Conversion isn't defined.\n";
	next;
      }
      my $q = $ngb->{convert}->{table}->{$name};
      if ($q->[0] eq "translit") {
	if ($c ne "") {
	  $r .= $m . "," . $name . $c . ".";
	  $m = "";
	  warn "$name: Transliteration doesn't allow \"$c\".\n";
	  next;
	}
	my $x = $ngb->{translit}->translit($q->[1], $m);
	if (! defined $x) {
	  $r .= $m . "," . $name . $c . ".";
	  $m = "";
	  warn "$name: Transliteration failed.\n";
	  next;
	}
	$r .= $x;
	$m = "";
	next;
      } else {
	my $mode = "j";
	if ($q->[1] eq "unicode") {
	  $mode = "u";
	} elsif ($q->[1] eq "tankanji") {
	  $mode = "J";
	}
	my @x = $ngb->{convert}->convert($m . "#$mode");
	if (@x == 0 || ! defined $x[0]) {
	  warn "$name: Conversion failed.\n";
	  $r .= $m . "," . $name . $c . ".";
	  $m = "";
	  next;
	}
	if (! ref $x[0]) {
	  $r .= $x[0];
	  $m = "";
	  next;
	}
	if ($c eq "") {
	  $r .= $x[0]->[0];
	  $m = "";
	  next;
	}
	if ($c =~ /^,+$/) {
	  my $kouho = length($c) - 1;
	  if ($kouho < @x) {
	    $r .= $x[$kouho]->[0];
	    $m = "";
	    next;
	  } else {
	    $r .= $m . "," . $name . $c . ".";
	    $m = "";
	    warn "$name: Conversion failed.\n";
	    next;
	  }
	} elsif ($c =~ /^(,+)([01-9a-zCVBG\;\/])$/) {
	  my $page = length($1) - 1;
	  my $cursor = index("1234567890qwertyuiopasdfghjklGzxcvbnmCVB", $2);
	  $cursor = index("1234567890qwertyuiopasdfghjkl;zxcvbnm,./", $2)
	    if $cursor == -1;
	  my $num = $page * 40 + $cursor;
	  my $y;
	  foreach my $x (@x) {
	    if ($x->[1] == $num) {
	      $y = $x->[0];
	      last;
	    }
	  }
	  if (defined $y) {
	    $r .= $y;
	    $m = "";
	    next;
	  } else {
	    $r .= $m . "," . $name . $c . ".";
	    $m = "";
	    warn "$name: Conversion failed.\n";
	    next;
	  }
	} else {
	  $r .= $m . "," . $name . $c . ".";
	  $m = "";
	  warn "$name: Conversion failed.\n";
	  next;
	}
      }
    }
    $r .= $m . $s;
    return $r;
  }

  sub decode { # naggy to alpha
    my $self = shift;
    $self->initialize() if ! $self->{initialized};

    my ($s) = @_;
    my $ngb = $self->{jc}->{ngb};

    my $r = "";
    while ($s ne "") {
      if ($s =~ /^\s+/s) {
	$s = $';
	$r .= $&;
      } elsif ($s =~ /^[\x21-\x7e]+/) {
	my $c = $&;
	$s = $';
	$c =~ s/,/,,/g;
	$r .= $c . ",a.";
      } elsif ($s =~ /^[\x{FF01}-\x{FF5E}]+/) {
	my $c = $&;
	$s = $';
	$c = $ngb->{translit}->translit("fw-hw", $c);
	$c =~ s/,/,,/g;
	$r .= $c . ",fw.";
      } elsif ($s =~ /^[\x{FF61}-\x{FF9F}]+/) {
	my $c = $&;
	$s = $';
	$c = $ngb->{translit}->translit("hwkata-alpha", $c);
	$c = lc($c);
	$c =~ s/,/,,/g;
	$r .= $c . ",hwkata.";
      } elsif ($s =~ /^[\x{3001}\x{3002}\x{300C}\x{300D}\x{3041}-\x{3094}\x{309B}\x{309C}\x{30FB}\x{30FC}]+/) {
	my $c = $&;
	$s = $';
	$c = $ngb->{translit}->translit("hira-alpha", $c);
	$c = lc($c);
	$c =~ s/,/,,/g;
	$r .= $c . ",h.";
      } elsif ($s =~ /^[\x{3001}\x{3002}\x{300C}\x{300D}\x{30A1}-\x{30F6}\x{309B}\x{309C}\x{30FB}\x{30FC}]+/) {
	my $c = $&;
	$s = $';
	$c = $ngb->{translit}->translit("kata-alpha", $c);
	$c = lc($c);
	$c =~ s/,/,,/g;
	$r .= $c . ",k.";
      } else {
	my $c = substr($s, 0, 1);
	$s = substr($s, 1);
	$c = sprintf("%x", ord($c));
	$r .= $c . ",u.";
      }
    }
    return $r;
  }
}

1;
