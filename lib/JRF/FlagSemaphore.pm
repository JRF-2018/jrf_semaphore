#!/usr/bin/perl
#require 5.008;
{ package JRF::FlagSemaphore;
  our $VERSION = "0.16"; # Time-stamp: <2020-01-24T03:01:00Z>
}

use strict;
use warnings;
#no autovivification qw(strict warn fetch exists delete store);
use utf8; # Japanese English

{
  package Resource;

  our $SEMAPHORE_ASM;
  $SEMAPHORE_ASM = "jrf_semaphore.asm" if ! defined $SEMAPHORE_ASM;
  our $SEMAPHORE_NES_ROM;
  $SEMAPHORE_NES_ROM = "jrf_semaphore.nes" if ! defined $SEMAPHORE_NES_ROM;
}

{
  package JRF::FlagSemaphore;
  use base qw(JRF::MyOO);

  use Encode qw();

  use JRF::Resource qw(locate_file_resource);
  use JRF::Utils qw(:all);
  use NES::ChrPage;
  use JRF::FlagSemaphore::Sailor;

   our $ASM = locate_file_resource($Resource::SEMAPHORE_ASM);
   our $ROM = locate_file_resource($Resource::SEMAPHORE_NES_ROM);
  our $CHR_NULL = "\x00";
  our $CHR_NULL2 = "\x03";
  our $CHR_CANCEL = "\x08";
  our $SCHR_DOT = "\x{FF65}";
  our $SCHR_DASH = "\x{FF0D}";
  our $SCHR_DELIM = "\x{FF03}";
  our $SCHR_RAW = "\x{FF04}";

  __PACKAGE__->extend_template
    (
     translit => undef,
     rmode => "",
     morse_code => "",
     smode => "letter",
     bits_point => [0, 0],
     bits_mark => [0, 0],
     bits => [(0) x 256],

     filename => undef,
     opt => {},
    );

  __PACKAGE__->extend_cvar
    (
     ASM_TEXT => JRF::MyOO::new_scalar(),
     CHECK_ID => JRF::MyOO::new_scalar(),
     ROM_HEADER => JRF::MyOO::new_scalar(),
     FLAG_CODE => [],
     FLAG_INV => {},
     MORSE_LEN_TABLE => [],
#     LOGO_CHR => {},
     SAILOR_CHR => [],
     FLAG_CHR => [],
     FLAG_LOC => [],
     CHR_PAGE => undef,
    );

  sub morse_code_to_ascii {
    my $self = ((ref $_[0])->isa(__PACKAGE__))? shift : undef;
    my $ref = shift;
    my %opt
      = (
	 error_char => "\x{FFFD}",
	 cancel_char => "\x{FFFD}",
	 cancel_mode_char => "",
	 mark_cancel => 0,
	 @_);
    my $s = (ref $ref)? $$ref : $ref;
    my $len_table = __PACKAGE__->get_cvar()->{MORSE_LEN_TABLE};
    $s =~ s/\s+//;
    $$ref = " " if ref $ref;
    my $err = $opt{error_char};
    my $cancel = $opt{cancel_char};
    my $cancel_mode = $opt{cancel_mode_char};

    my $mode = "";
    if ($s =~ s/^[\&_]//) {
      $mode = $&;
    }
    my $len = length($s);
    if ($len == 0) {
      return $mode;
    }
    $s =~ tr/\.\-/01/;
    if ($len >= 9) {
      if ($s =~ /^0+$/) {
	my $r = $cancel;
	if ((ref $ref) && $$ref ne "") {
	  $r = $cancel_mode;
	}
	$$ref = "" if ref $ref;
	return $r;
      }
      return $mode . $err;
    }
    my $c = unpack("C", (pack("b" . $len, scalar reverse($s))));
    if ($mode eq "&" && $len <= 8) {
      return chr($c);
    }
    if ($len == 8) {
      if ($c == 0) {
	my $r = $cancel;
	if ((ref $ref) && $$ref ne "") {
	  $r = $cancel_mode;
	}
	$$ref = "" if ref $ref;
	return $r;
      }
      return $mode . $err;
    }

    if ($len == 7) {
      if ($c == 0b0001001) {
	return "\$";
      }
      return $mode . $err;
    }

    $c = $len_table->[(1 << $len) - 1 + $c];
    if ($c == 0) {
      return $mode . $err;
    }
    $c = chr($c);
    if ($mode eq "_") {
      if ($c =~ tr/_\&\x27\x22\-\//_\&\`\^\~\x5c/) {
	return $c;
      }
      return uc($c);
    }
    if ($c eq "&") {
      if (ref $ref) {
	$$ref = "&";
	return "";
      } else {
	return "&";
      }
    }
    if ($c eq "_") {
      if (ref $ref) {
	$$ref = "_";
	return "";
      } else {
	return "_";
      }
    }
    return $c;
  }

  sub flag_code_to_string {
    my $self = (ref $_[0])? shift : undef;
    my $s = shift;
    my %opt
      = (
	 error_char => "\x{FFFD}",
	 cancel_char => "\x{FFFD}",
	 cancel_mode_char => "",
	 mark_cancel => "",
	 @_);
    my $r = "";
    my $morse_code = "";
    my $mode = "";
    my $flag_code;
    if (defined $self) {
      $flag_code = $self->{cvar}->{FLAG_CODE};
      $mode = $self->{rmode};
      $morse_code = $self->{morse_code};
    } else {
      $flag_code = __PACKAGE__->get_cvar()->{FLAG_CODE};
    }
    $mode = $opt{mode} if exists $opt{mode};
    my $err = encode_u($opt{error_char});
    my $cancel = encode_u($opt{cancel_char});
    my $cancel_mode = encode_u($opt{cancel_mode_char});

    while ($s ne "") {
      my $c = ord(substr($s, 0, 1));
      $s = substr($s, 1);
      my $x = $flag_code->[($c >> 4) * 8 + ($c & 7)];
      if (defined $x) {
	$x = lc(chr($x));
      } else {
	$x = $err;
      }

      if (defined $self && ($c == 0x77 || $c == 0x70 || $c == 0x07)) {
	if ($mode =~ /^\&/) {
	  if ($c == 0x07) {
	    $self->{bits_point}->[0] = $self->{bits_point}->[0] | 8;
	  } elsif ($c == 0x70) {
	    $self->{bits_point}->[0] = $self->{bits_point}->[0] & 0xF7;
	  }
	} elsif ($self->{bits_point}->[0] & 8) {
	  if ($c == 0x77) {
	    my $mask = 1 << ($self->{bits_point}->[0] & 7);
	    $self->{bits}->[$self->{bits_point}->[1]]
	      = $self->{bits}->[$self->{bits_point}->[1]] ^ $mask;
	  } elsif ($c == 0x07) {
	    $self->{bits_point}->[0]
	      = (($self->{bits_point}->[0] + 1) & 7) | 8;
	    if (($self->{bits_point}->[0] & 7) == 0) {
	      $self->{bits_point}->[1]
		= ($self->{bits_point}->[1] + 1) & 0xff;
	    }
	  } elsif ($c == 0x70) {
	    $self->{bits_point}->[0]
	      = (($self->{bits_point}->[0] - 1) & 7) | 8;
	    if (($self->{bits_point}->[0] & 7) == 0) {
	      $self->{bits_point}->[1]
		= ($self->{bits_point}->[1] - 1) & 0xff;
	    }
	  }
	} else {
	  if ($c == 0x77) {
	    @{$self->{bits_mark}} = @{$self->{bits_point}};
	  } else {
	    my $mask = 1 << ($self->{bits_point}->[0] & 7);
	    if ($c == 0x07) {
	      $self->{bits}->[$self->{bits_point}->[1]]
		= $self->{bits}->[$self->{bits_point}->[1]] & (0xff ^ $mask);
	    } elsif ($c == 0x70) {
	      $self->{bits}->[$self->{bits_point}->[1]]
		= $self->{bits}->[$self->{bits_point}->[1]] | $mask;
	    }
	    $self->{bits_point}->[0]
	      = ($self->{bits_point}->[0] + 1) & 7;
	    if (($self->{bits_point}->[0] & 7) == 0) {
	      $self->{bits_point}->[1]
		= ($self->{bits_point}->[1] + 1) & 0xff;
	    }
	  }
	}
      }

      if ($mode eq ".") {
	if ($x eq ".") {
	  $morse_code .= ".";
	  next;
	} elsif ($x eq "_" || $x eq "f") {
	  $morse_code .= "-";
	  $mode = "";
	  next;
	} elsif ($x eq "\x00") {
	  $morse_code .= ".";
	  $mode = "";
	  next;
	} else {
	  $morse_code .= ".";
#	  print "MORSE_OUT \"$morse_code\"\n";
	  $r .= encode_u(morse_code_to_ascii(\$morse_code, %opt));
	  $mode = "";
	}
      }
 #     print "\"$r\" \"$mode\"\n";
      if ($x eq "." && $mode ne "_") {
#	print "MORSE_IN\n";
	if ($mode ne "" && $mode ne "\$") {
	  $r .= $err;
	}
	if ($morse_code =~ /^[\$_ ] /) {
	  $r .= " ";
	}
	$morse_code =~ s/\s+//;
	$mode = ".";
	next;
      }
      if ($x ne "." && $morse_code !~ /^\s*$/) {
#	print "MORSE_OUT \"$morse_code\" \"$r\"\n";
	$r .= encode_u(morse_code_to_ascii(\$morse_code, %opt));
	$mode = "";
      }
      if ($x eq "_" && $mode ne "_") {
	if ($mode ne "" && $mode ne "\$") {
	  $r .= $err;
	  $mode = "";
	}
	$mode = $mode . "_";
	next;
      }
      if ($x eq $CHR_NULL) {
	if (length($morse_code) > 0 && length($morse_code) < 3)  {
	  $morse_code .= " ";
	}
	next;
      }
      if ($x eq $CHR_NULL2) {
	$morse_code =~ s/ +//;
	next;
      }
      if ($x eq $CHR_CANCEL) {
	if ($morse_code eq "" && $mode eq "") {
	  $r .= $cancel;
	} else {
	  $r .= $cancel_mode;
	}
	$morse_code = "";
	$mode = "";
	next;
      }
      if ($x eq "\$") {
	$morse_code = "";
	if ($mode ne "" && $mode ne "\$") {
	  $r .= $err;
	}
	$mode = "\$";
	next;
      }
      if ($x eq "\&") {
	$morse_code = "";
	if ($mode ne "" && $mode ne "\$") {
	  $r .= $err;
	}
	$mode = "\&";
	next;
      }
      if ($x eq 'j' && $mode =~ /^\$/) {
	if (length($') > 0) {
	  $r .= $err;
	}
	$mode = "";
	next;
      }

      if ($mode eq "\$_") {
	if ($x eq 'k') {
	  $r .= "0";
	  $mode = "\$";
	  next;
	} elsif (ord($x) >= ord("a") && ord($x) <= ord("i")) {
	  $r .= chr(ord($x) - ord("a") + ord("1"));
	  $mode = "\$";
	  next;
	} else {
	  $mode = "\$";
	  $r .= $err;
	  next;
	}
      }
      if ($mode eq "\&_") {
	if ($x eq 'k') {
	  $r .= "0";
	  $mode = "";
	  next;
	} elsif (ord($x) >= ord("a") && ord($x) <= ord("i")) {
	  $r .= chr(ord($x) - ord("a") + ord("1"));
	  $mode = "";
	  next;
	} else {
	  $mode = "";
	  $r .= $err;
	  next;
	}
      }
      if ($mode =~ /^[\$\&]([01-9]*)/) {
	my $oct = $1;
	if ($x eq '_' && $oct eq "") {
	  $mode .= "_";
	  next;
	} elsif ($x eq 'k') {
	  $oct .= "0";
	} elsif (ord($x) >= ord("a") && ord($x) <= ord("i")) {
	  $oct .= chr(ord($x) - ord("a") + ord("1"));
	} else {
	  $mode = ($mode =~ /^\$/)? "\$" : "";
	  $r .= $err;
	  next;
	}
	if (length($oct) == 2 && substr($oct, 0, 1) =~ /^[4-9]$/) {
	  my $l = substr($oct, 1, 1);
	  my $m = substr($oct, 0, 1);
	  my $h = 0;
	  if ($m == 8) {
	    $h = 1;
	    $m = ($l == 0)? 0 : 3;
	  } elsif ($m == 9) {
	    $h = 1;
	    $m = ($l == 0)? 4 : 7;
	  }
	  $r .= chr(($h << 6) | ($m << 3) | $l);
	  $mode = ($mode =~ /^\$/)? "\$" : "";
	  next;
	} elsif (length($oct) == 3) {
	  my $l = substr($oct, 2, 1);
	  my $m = substr($oct, 1, 1);
	  my $h = substr($oct, 0, 1);
	  $r .= chr(($h << 6) | ($m << 3) | $l);
	  $mode = ($mode =~ /^\$/)? "\$" : "";
	  next;
	} else {
	  $mode = substr($mode, 0, 1) . $oct;
	  next;
	}
      }
      if ($mode eq '_') {
	$mode = "";
	if ($x eq ".") {
	  $r .= ".";
	  next;
	} elsif ($x eq " ") {
	  $r .= ",";
	  next;
	}
	$x = uc($x);
      }
      $r .= $x;
    }
    if ((! defined $self) || (exists $opt{flush} && $opt{flush})) {
      if ($mode eq ".") {
	$morse_code .= ".";
	$mode = "";
	$r .= encode_u(morse_code_to_ascii(\$morse_code, %opt));
      }
      $morse_code =~ s/ +$//;
      $r .= $morse_code;
      $morse_code = "";
      if ($mode ne "" && $mode ne "\$") {
	$r .= $err;
      }
      $mode = "";
    }
    if (defined $self) {
      $self->{rmode} = $mode;
      $self->{morse_code} = $morse_code;
    }

    $r = decode_u($r);
    return $r;
  }

  sub string_to_flag_code {
    my $self = (ref $_[0])? shift : undef;
    my ($s, %opt) = @_;
    my $r;
    $s = encode_u($s);
    if (defined $self) {
      $r = $self->ascii_to_flag_code($s, %opt);
    } else {
      $r = ascii_to_flag_code($s, %opt);
    }
    return $r;
  }

#  sub _raw_ascii_to_flag_code {
#    my ($tbl, $c) = @_;
#    $c = ord(lc($c));
#    if (exists $tbl->{$c}) {
#      return chr($c);
#    }
#    return undef;
#  }

  sub _concat_flag_code {
    my ($a, $b) = @_;
    return $a if $b eq "";
    return $b if $a eq "";
    my $la = substr($a, -1);
    my $bb = substr($b, 0, 1);
    if ($la eq $bb && $la ne "\x00") {
      return $a . "\x00" . $b;
    }
    return $a . $b;
  }

  sub ascii_to_flag_code {
    my $self = (ref $_[0])? shift : undef;
    my ($s, %opt) = @_;
    my $r = "";
    my $mode = "letter";
    my $flag_inv;
    if (defined $self) {
      $mode = $self->{smode};
      $flag_inv = $self->{cvar}->{FLAG_INV};
    } else {
      $flag_inv = __PACKAGE__->get_cvar()->{FLAG_INV};
    }
    $mode = $opt{mode} if exists $opt{mode};

    while ($s ne "") {
      my $c = substr($s, 0, 1);
      my $x = ord($c) & 0xFF;
      $s = substr($s, 1);
      my $d;
      my $next;

      if ($c eq $SCHR_DOT) {
	$d = "\x04\x00";
	$next = "morse";
      } elsif ($c eq $SCHR_DASH) {
	$d = "\x04\x06";
	$next = "morse";
      } elsif ($c eq $SCHR_DELIM) {
	$d = "\x07";
	$next = $mode;
      } elsif ($c eq $SCHR_RAW) {
	$d = "";
	$next = "raw";
      } elsif ($x >= ord("a") && $x <= ord("z")) {
	$d = chr($flag_inv->{$x});
	$next = "letter";
      } elsif ($x >= ord("A") && $x <= ord("Z")) {
	$d = _concat_flag_code(chr($flag_inv->{ord("_")}),
			       chr($flag_inv->{$x + ord("a") - ord("A")}));
	$next = "letter";
      } elsif ($x >= ord("0") && $x <= ord("9")) {
	if ($mode eq "raw") {
	  $d = chr($flag_inv->{$x});
	  $next = "raw";
	} else {
	  $d = _concat_flag_code(chr($flag_inv->{ord("_")}),
				 chr($flag_inv->{$x}));
	  $next = "number";
	}
      } elsif ($x == ord(" ")) {
	$d = chr($flag_inv->{ord(" ")});
	$next = $mode;
      } elsif ($x == ord(".")) {
	$d = _concat_flag_code(chr($flag_inv->{ord("_")}),
			       chr($flag_inv->{$x}));
	$next = $mode;
      } elsif ($x == ord(",")) {
	$d = _concat_flag_code(chr($flag_inv->{ord("_")}),
			       chr($flag_inv->{ord(" ")}));
	$next = $mode;
      } else {
	my $l = $x & 0x7;
	my $m = ($x >> 3) & 0x7;
	my $h = ($x >> 6) & 0x7;
	$d = chr($flag_inv->{$l + ord("0")});
	if ($h == 0 && $m >= 4) {
	  $d = _concat_flag_code(chr($flag_inv->{$m + ord("0")}), $d);
	} elsif (($h == 1 && $m == 0 && $l == 0)
		 || ($h == 1 && $m == 3 && $l != 0)) {
	  $d = _concat_flag_code(chr($flag_inv->{ord("8")}), $d);
	} elsif (($h == 1 && $m == 4 && $l == 0)
		 || ($h == 1 && $m == 7 && $l != 0)) {
	  $d = _concat_flag_code(chr($flag_inv->{ord("9")}), $d);
	} else {
	  $d = _concat_flag_code(chr($flag_inv->{$m + ord("0")}), $d);
	  $d = _concat_flag_code(chr($flag_inv->{$h + ord("0")}), $d);
	}
	if ($mode eq "letter"
	    && $s ne "" && substr($s, 0, 1) =~ /^[A-Za-z]/) {
	  $d = _concat_flag_code(chr($flag_inv->{ord("\&")}), $d);
	  $next = "letter";
	} else {
	  $next = "number";
	}
      }

      if ($mode ne $next) {
	if ($next eq "letter" && ($mode eq "raw" || $mode eq "number")) {
	  $d = _concat_flag_code(chr($flag_inv->{ord("j")}), $d);
	} elsif (($next eq "raw" || $next eq "number") &&
		 ! ($mode eq "raw" || $mode eq "number")) {
	  $d = _concat_flag_code(chr($flag_inv->{ord("\$")}), $d);
	}
	$mode = $next;
      }
      $r = _concat_flag_code($r, $d);
    }
    if (defined $self) {
      $self->{smode} = $mode;
    }
    return $r;
  }

  sub new_sailor {
    my $self = shift;
    return (__PACKAGE__ . "::Sailor")->new($self, @_);
  }

  sub generate_sav {
    my $self = shift;
    my $s = shift;
    my %opt = (font8x16 => 0,
	       toprintable => 1,
	       righttoleft => 0,
	       chr_page8k => 2,
	       font => 1,
	       color => 1,
	       @_);
    $s = encode_u($s);
    if (length($s) > 255) {
      $s = substr($s, -255);
    }
    my $len = length($s);
    $s .= "\x00" x (0x100 - $len);
    my $sav = "\x00" x 0x2000;
    my $check_id = ${$self->{cvar}->{CHECK_ID}};
    substr($sav, 0, length($check_id)) = $check_id;
    substr($sav, 0x10, 1) = pack("C", $len);
    my $opt = pack_bits("B4BBBB", $opt{chr_page8k}, 0, 
			$opt{righttoleft}, $opt{toprintable}, $opt{font8x16});
    $opt = $opt{sav_switch}
      if exists $opt{sav_switch} && defined $opt{sav_switch};
    substr($sav, 0x13, 1) = pack("C", $opt);
    substr($sav, 0x14, 1) = pack("C", $opt{font}) if exists $opt{font};
    substr($sav, 0x15, 1) = pack("C", $opt{color}) if exists $opt{color};
    substr($sav, 0x20, 4) = pack("C4", @{$self->{bits_point}},
				 @{$self->{bits_mark}});
    substr($sav, 0x100, 0x100) = $s;
    substr($sav, 0x200, 0x100) = pack("C256", @{$self->{bits}});
    return $sav;
  }

  sub new {
    my $class = shift;
    my $obj =  $class->SUPER::new(@_);
    if (@_ % 2 == 1) {
      unshift(@_, "file");
    }
    %{$obj->{opt}} = (%{$obj->{opt}}, @_);
    return $obj;
  }

 ClassInit:
  {
    my $cvar = __PACKAGE__->get_cvar();
    my $asm;
    my $rom;
    my $version;
    my $check_id;
    my $tables = {};
    my $tables_num;

    my $parse_data = sub {
      my ($line) = @_;
      $line =~ s/\;.*$//s;
      if ($line !~ /^\s*\.?(?:db|dw|byte|word)\s+/is) {
	return ();
      }
      my (@l) = split(/\s*,\s*/, $');
      my @r;
      foreach my $c (@l) {
	if ($c =~ /^\s*\"(.*)\"\s*$/s) {
	  push(@r, ["number", unpack("C*", $1)]);
	} elsif ($c =~ /^\s*\'(.)\'\s*$/s) {
	  push(@r, ["number", ord($1)]);
	} elsif ($c =~ /^\s*\%([01]+)\s*$/s) {
	  push(@r, ["number", unpack("C",  pack("B8", $1))]);
	} elsif ($c =~ /^\s*\$([01-9A-Fa-f]+)\s*$/s) {
	  push(@r, ["number",hex($1)]);
	} elsif ($c =~ /^\s*([01-9]+)\s*$/s) {
	  push(@r, ["number", int($1)]);
	} elsif ($c =~ /^\s*([A-Za-z01-9_]+)\s*$/s) {
	  push(@r, ["symbol", $1]);
	} else {
	  die "$ASM: Parse Error.";
	}
      }
      @l = @r;
      @r = ();
      while (@l) {
	my $c = shift(@l);
	if ($c->[0] ne "symbol") {
	  while (@l) {
	    my $d = $l[0];
	    last if $d->[0] eq "symbol";
	    shift(@l);
	    shift(@$d);
	    shift(@$c);
	    $c = ["number", @$c, @$d];
	  }
	}
	push(@r, $c);
      }
      return @r;
    };

    {
      open(my $fh, "<", encode_fn($ASM)) or die "$ASM: $!";
      binmode($fh, ":utf8");
      $asm = join("", <$fh>);
      close($fh);
    }

    {
      open(my $fh, "<", encode_fn($ROM)) or die "$ASM: $!";
      binmode($fh);
      $rom = join("", <$fh>);
      close($fh);
    }

    ${$cvar->{ASM_TEXT}} = $asm;

    {
      my $s = $asm;
      if ($s !~ /^((?:[^\n]*\n){0,16})/s) {
	die "$ASM: Parse Error.";
      }
      $s = $1;
      if ($s !~ /(?:JRF_VERSION[^\n]*\n?[^\n]*[\"']([^\"'\s]+)[\"'])/s) {
	die "$ASM: Parse Error.$s";
      }
      $version = $1;
    }

    {
      my $s = $asm;
      my @r;
      my @n;
      if ($s !~ /\nCheckID\:(\s+\.?(?:db|byte|DB|BYTE)[^\n]+)/s) {
	die "$ASM: Parse Error.";
      }
      $s = $1 . $';
      while ($s =~ /^\s+(\.?(?:db|byte)\s+[^\n]+)/is) {
	$s = $';
	@r = &{$parse_data}($1);
	if (@r != 1 && $r[0]->[0] ne "number") {
	  die "$ASM: Parse Error.";
	}
	shift(@{$r[0]});
	push(@n, @{$r[0]});
	last if grep {$_ == 0} @n;
      }
      if (! grep {$_ == 0} @n) {
	  die "$ASM: Parse Error.";
      }
      @r = ();
      while (@n) {
	my $c = shift(@n);
	last if $c == 0;
	push(@r, $c);
      }
      if (@r == 0) {
	die "$ASM: Parse Error.";
      }
      $check_id = pack("C*", @r);
      ${$cvar->{CHECK_ID}} = $check_id;
    }

    {
      my $s = $asm;
      if (($s !~ /\nPublicSymbols\:[^\n]*\n(.*\n)PublicSymbolsEnd\:/s) 
	  || ($s !~ /\nTables\:[^\n]*\n(.*\n)TablesEnd\:/s)) {
	die "$ASM: Parse Error.";
      }
      $s = $1;
      my @r;
      while ($s =~ /^([^\n]+)\n/s) {
	$s = $';
	my $c = $1;
	push(@r, &{$parse_data}($c)) if $c !~ /^[A-Za-z\._]/;
      }
      if (@r == 0 || ! ($r[$#r]->[0] eq "number" && $r[$#r]->[1] == 0)) {
	die "$ASM: Parse Error.";
      }
      $tables_num = scalar @r;
      for (my $i = 0; $i < @r; $i++) {
	my $c = $r[$i];
	if ($c->[0] eq "symbol") {
	  my $e = $c->[1];
	  $e =~ s/^_//;
	  $tables->{$e} = {};
	  $tables->{$e}->{num} = $i;
	}
      }
      if (! exists $tables->{"CheckID"}) {
	die "$ASM: Parse Error.";
      }
    }

    {
      my $s = $rom;
      if ($s !~ /\Q$check_id\E\x00[^\x00]*\Q$version\E[^\x00]*\x00/s) {
	die "$ROM: Parse Error.";
      }
      my $id_addr = length($`);
      my $tb_addr = $id_addr + length($&);
      my @addr = unpack("S*", pack("s*", unpack("v*", substr($', 0, 2 * $tables_num))));
      if ($addr[$#addr] != 0) {
	die "$ROM: Parse Error.";
      }
      my $id_raddr = $addr[$tables->{"CheckID"}->{num}];
      foreach my $k (keys %$tables) {
	my $ra = $addr[$tables->{$k}->{num}];
	$tables->{$k}->{addr} = $addr[$tables->{$k}->{num}] - $id_raddr + $id_addr;
      }
    }

    if (! exists $tables->{"FlagCode"}) {
      die "$ROM: Parse Error.";
    }
    @{$cvar->{FLAG_CODE}} = unpack("C*", substr($rom, $tables->{"FlagCode"}->{addr}, 8 * 8));

    if (! exists $tables->{"MorseCodeLenTable"}) {
      die "$ROM: Parse Error.";
    }
    @{$cvar->{MORSE_LEN_TABLE}}
      = unpack("C*", substr($rom, $tables->{"MorseCodeLenTable"}->{addr}, (1 << (6 + 1)) - 1));

    if (! exists $tables->{"SailorChr"}) {
      die "$ROM: Parse Error.";
    }
    {
      my @r;
      my $addr = $tables->{"SailorChr"}->{addr};

      for (my $i = 0; $i < 2 * 4; $i++) {
	push(@r, [unpack("C*", substr($rom, $addr + 5 * $i, 5))]);
      }
      @{$cvar->{SAILOR_CHR}} = @r;
    }

    if (! exists $tables->{"FlagChr"}) {
      die "$ROM: Parse Error.";
    }
    {
      my @r;
      my $addr = $tables->{"FlagChr"}->{addr};

      for (my $i = 0; $i < 32; $i++) {
	push(@r, [unpack("C*", substr($rom, $addr + 5 * $i, 5))]);
      }
      @{$cvar->{FLAG_CHR}} = @r;
    }

    if (! exists $tables->{"FlagLoc"}) {
      die "$ROM: Parse Error.";
    }
    {
      my @r;
      my $addr = $tables->{"FlagLoc"}->{addr};

      for (my $i = 0; $i < 16; $i++) {
	push(@r, [unpack("c*", substr($rom, $addr + 2 * $i, 2))]);
      }
      @{$cvar->{FLAG_LOC}} = @r;
    }

    {
      my @flag_code = @{$cvar->{FLAG_CODE}};
      my %flag_inv = ();
      for (my $l = 0; $l < 8; $l++) {
	for (my $r = 0; $r < 8; $r++) {
	  my $v = $flag_code[$l * 8 + $r];
	  my $c = ($l  << 4) | $r;
	  next if $v == ord('?');
	  next if lc(chr($v)) ne chr($v);
	  if (! exists $flag_inv{$v}) {
	    $flag_inv{$v} = $c;
	  } elsif ($v == 0x03 && $c == 0x07) {
	    $flag_inv{$v} = $c;
	  }
	}
      }
      $flag_inv{ord('0')} = $flag_inv{ord('k')};
      for (my $i = ord('1'); $i <= ord('9'); $i++) {
	$flag_inv{$i} = $flag_inv{$i - ord('1') + ord('a')};
      }
      %{$cvar->{FLAG_INV}} = %flag_inv;
    }

    ${$cvar->{ROM_HEADER}}  = substr($rom, 0, 0x10);
    if (! exists $tables->{"PaletteSize"}) {
      die "$ROM: Parse Error.";
    }
    if (! exists $tables->{"Palette"}) {
      die "$ROM: Parse Error.";
    }
    {
      my $sz = unpack("C", substr($rom, $tables->{"PaletteSize"}->{addr}, 1));
      my $pal = [unpack("C*", substr($rom, $tables->{"Palette"}->{addr}, $sz))];
      $cvar->{CHR_PAGE} = NES::ChrPage->new($rom, palettes => $pal);
    }
  }
}

1;
