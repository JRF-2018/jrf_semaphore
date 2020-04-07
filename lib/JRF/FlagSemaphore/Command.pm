#!/usr/bin/perl
#require 5.008;
{ package JRF::FlagSemaphore::Command;
  our $VERSION = "0.15"; # Time-stamp: <2020-01-23T08:23:55Z>
}

use strict;
use warnings;
#no autovivification qw(strict warn fetch exists delete store);
use utf8; # Japanese English

{
  package JRF::FlagSemaphore::NgbCommand;
  use base qw(Naggy::Backend::CommandInterface);

  use Naggy;
  use JRF::Resource qw(locate_file_resource);
  use GifFont;
  use GifFont::JRFSemaphoreRom;

  __PACKAGE__->extend_template
    (
     jc => undef,

     allow_trl_init => 0,
    );

  __PACKAGE__->extend_cvar
    (
     ABBREV_gif_font => "gif_font",
     ABBREV_sav_default => \&sav_default, # CODE ref for debug.
     ABBREV_trl_init => "trl_init",
     ABBREV_giffont => "gif_font",
     ABBREV_savdefault => "sav_default",
     ABBREV_trlinit => "trl_init",
     ABBREV_find_resource => "find_resource",
    );

  sub new {
    my $class = shift;
    my ($jc, @rest) = @_;
    my $obj =  $class->SUPER::new($jc->{ngb}, @rest);
    $obj->{jc} = $jc;
    return $obj;
  }

  sub gif_font {
    my $self = shift;
    my $ngb = $self->{ngb};
    my $JC = $self->{jc};
    if (@_ < 2) {
      $ngb->rerror("gif-font: illegal arguments.");
      return;
    }
    my $trl = shift;
    if (@_ % 2 == 1) {
      unshift(@_, "file");
    }
    my %opt = @_;
    my $gf;
    if (exists $opt{"--nes"} || exists $opt{nes}) {
      $gf = GifFont::JRFSemaphoreRom->new(@_);
    } else {
      $gf = GifFont->new(@_);
    }
    if (defined $gf) {
      $JC->{gif_font}->{$trl} = $gf;
      $ngb->rprint("# begin unit\nok\n# end\n");
    } else {
      $ngb->rerror("load failure.");
    }
  }

  sub sav_default {
    my $self = shift;
    my $ngb = $self->{ngb};
    my $JC = $self->{jc};
    if (@_ < 2 && @_ % 2 != 1) {
      $ngb->rerror("sav-default: illegal arguments.");
      return;
    }
    my $trl = shift;
    $JC->{sav_default}->{$trl} = [@_];
    $ngb->rprint("# begin unit\nok\n# end\n");
  }

  sub trl_init {
    my $self = shift;
    my $ngb = $self->{ngb};
    my $JC = $self->{jc};
    if (! $self->{allow_trl_init}) {
      $ngb->rerror("trl-init: forbidden.");
      return;
    }
    if (@_ != 2) {
      $ngb->rerror("trl-init: illegal arguments.");
      return;
    }
    my $trl = shift;
    my $f = shift;

    $JC->{trl_init}->{$trl} = $f;
    $ngb->rprint("# begin unit\nok\n# end\n");
  }

  sub find_resource {
    my $self = shift;
    my $ngb = $self->{ngb};
    my ($file, @path) = @_;
    if (@_ != 1) {
      $ngb->rerror("find-resource: illegal arguments. Usage: find-resource file");
      return;
    }
    my $r = locate_file_resource($file);
    if (defined $r) {
      $ngb->rprint("# begin string\n" . Naggy::escape_string($r) . "\n# end\n");
    } else {
      $ngb->rerror("find-resource: $file doesn't exists in the path.");
    }
  }
}


{
  package JRF::FlagSemaphore::Command;
  use base qw(JRF::MyOO);

  use Encode qw();
  use IO::Handle;
  use Pod::Usage;
  use Getopt::Long qw();
  use Carp;

  use JRF::Resource qw(locate_file_resource);
  use JRF::Utils qw(:all);
  use Naggy::Backend::Translit;
  use JRF::FlagSemaphore;
  use JRF::FlagSemaphore::Naggy;
#  use JRF::FlagSemaphore::NgbCommand;
  use GifFont::JRFSemaphoreRom;

  __PACKAGE__->extend_template
    (
     j => undef,
     translit => undef,
     ngb => undef,
     gif_font => {},
     sav_default => {},
     trl_init => {},
     special_trl => {},
     ngb_init_string => undef,

     main_mode => undef,
     trl => undef,
     output_mode => 0,
     mode_opt => [],
     output => undef,
     input => undef,
    );

  our $NGB_INIT = "site-init.nginit";
  our %GIF_FONT;
  our %SAV_DEFAULT;
  our %TRL_NGINIT;

  sub new {
    my $class = shift;
    my $obj =  $class->SUPER::new(@_);
    $obj->{j} = JRF::FlagSemaphore->new();
    $obj->{translit} = Naggy::Backend::Translit->new();
    %{$obj->{gif_font}} = %GIF_FONT;
    %{$obj->{sav_default}} = %SAV_DEFAULT;
    %{$obj->{trl_init}} = %TRL_NGINIT;
    $obj->{special_trl}->{naggy} = JRF::FlagSemaphore::Naggy->new($obj);
    return $obj;
  }

  sub prepare_trl {
    my $self = shift;
    my ($trlid, $trlname) = @_;
    my $T = $self->{translit};
    return $trlname if exists $T->{table}->{$trlname};
    if (! defined $self->{ngb}) {
      $self->init_naggy_backend();
      croak "Naggy::Backend: failed to invoke." if ! defined $self->{ngb};
    }
    return $trlname if exists $T->{table}->{$trlname};
    croak "$trlname: not found." if ! exists $self->{trl_init}->{$trlid};
    my $fn = locate_file_resource($self->{trl_init}->{$trlid});
    $self->{ngb}->load_init_file($fn);
    return $trlname if exists $T->{table}->{$trlname};
    croak "$trlname: not found.";
  }

  sub init_naggy_backend {
    my $self = shift;
    my $ngb = $self->{ngb};
    if (! defined $ngb) {
      require Naggy::Backend;
      $ngb = Naggy::Backend->new(translit => $self->{translit});
      return undef if ! defined $ngb;
      $self->{ngb} = $ngb;
    }
    my $ci = JRF::FlagSemaphore::NgbCommand->new($self);
    foreach my $k (%{(ref $ci)->get_cvar()}) {
      if ($k =~ /^ABBREV_/) {
	my $n = $';
	$n =~ s/_/\-/g;
	$ngb->{command}->{$n} = $ci;
      }
    }
    $ngb->{INIT_VAR}->{"HOME"} = $ENV{HOME};
    $ngb->{INIT_VAR}->{"FRONT_END"} = "jrf_semaphore";

    my $init = $self->{ngb_init_string};
    if (! defined $init && defined $NGB_INIT) {
      my $fn = locate_file_resource($NGB_INIT);
      open(my $fh, "<", $fn) or die "$NGB_INIT: $!";
      $init = join("", <$fh>);
      close($fh);
    }
    if (defined $init) {
      $ci->{allow_trl_init} = 1;
      $ngb->load_init_file_from_string($init);
      $ci->{allow_trl_init} = 0;
    }

    return $ngb;
  }

  sub encode {
    my $self = shift;
    my $J = $self->{j};
    my $T = $self->{translit};
    my $s = shift;
    my %opt
      = (
	 trl => $self->{trl},
	 @{$self->{mode_opt}},
	 @_
	);
    my $init = "jrf ";
    $init .= "t $opt{trl} " if defined $opt{trl};
    $init .= $opt{protocol} . " " if defined $opt{protocol};
    $init .= "c ";
    if (defined $opt{trl}) {
      if (exists $self->{special_trl}->{$opt{trl}}) {
	$s = $self->{special_trl}->{$opt{trl}}->decode($s);
      } else {
	my $trl = $opt{trl} . "-alpha";
	$self->prepare_trl($opt{trl}, $trl);
	$s = $T->translit($trl, $s);
      }
    }
    if (! exists $opt{without_init_protocol}
	|| ! exists $opt{without_init_protocol}) {
      $s = $init . $s;
    }
    return $J->string_to_flag_code($s, @{$self->{mode_opt}}, flush => 1, @_);
  }

  sub decode {
    my $self = shift;
    my $J = $self->{j};
    my $T = $self->{translit};
    my $s = shift;
    my %opt
      = (
	 trl => $self->{trl},
	 @{$self->{mode_opt}},
	 @_
	);
    $s = $J->flag_code_to_string($s, @{$self->{mode_opt}}, flush => 1, @_);
    my $init;
    if ($s =~ /^jrf / && $s =~ / c /) {
      $init = $` . $&;
      $s = $';
    }
    if (! defined $init) {
      warn "The input seems not to be flag codes, but proceeding.\n";
    } else {
      $init =~ s/^jrf //;
      $init =~ s/ ?c $//;
      my %o = split(/\s+/, $init);
      if (exists $o{t} && ! defined $opt{trl}) {
	$opt{trl} = $o{t};
	$self->{trl} = $o{t};
      }
    }
    if (defined $opt{trl}) {
      if (exists $self->{special_trl}->{$opt{trl}}) {
	$s = $self->{special_trl}->{$opt{trl}}->encode($s);
      } else {
	my $trl =  "alpha-" . $opt{trl};
	$self->prepare_trl($opt{trl}, $trl);
	$s = $T->translit($trl, $s);
      }
    }
    return $s;
  }

  sub translit_encode {
    my $self = shift;
    my $T = $self->{translit};
    my $s = shift;
    my %opt
      = (
	 trl => $self->{trl},
	 @{$self->{mode_opt}},
	 @_
	);
    if (defined $opt{trl}) {
      if (exists $self->{special_trl}->{$opt{trl}}) {
	$s = $self->{special_trl}->{$opt{trl}}->encode($s);
      } else {
	my $trl = "alpha-" . $opt{trl};
	$self->prepare_trl($opt{trl}, $trl);
	$s = $T->translit($trl, $s);
      }
    } else {
      die "No transliteration table was specifiled.";
    }
    return $s;
  }

  sub translit_decode {
    my $self = shift;
    my $T = $self->{translit};
    my $s = shift;
    my %opt
      = (
	 trl => $self->{trl},
	 @{$self->{mode_opt}},
	 @_
	);
    if (defined $opt{trl}) {
      if (exists $self->{special_trl}->{$opt{trl}}) {
	$s = $self->{special_trl}->{$opt{trl}}->decode($s);
      } else {
	my $trl = $opt{trl} . "-alpha";
	$self->prepare_trl($opt{trl}, $trl);
	$s = $T->translit($trl, $s);
      }
    } else {
      die "No transliteration table was specifiled.";
    }
    return $s;
  }

  sub text_gif {
    my $self = shift;
    my $s = shift;
    my %opt
      = (
	 trl => $self->{trl},
	 @{$self->{mode_opt}},
	 @_
	);
    $opt{trl} = "ascii" if ! defined $opt{trl};
    $self->prepare_trl($opt{trl}, "ascii-" . $opt{trl})
      if ! exists $self->{gif_font}->{$opt{trl}};
    if (exists $self->{gif_font}->{$opt{trl}}) {
      my $gf = $self->{gif_font}->{$opt{trl}};
      return $gf->text_gd($s, @{$self->{mode_opt}}, @_)->gif();
    } else {
      die "No transliteration table was specifiled.";
    }
  }

  sub flag_gif {
    my $self = shift;
    my $J = $self->{j};
    my $s = shift;
    my $sailor = $J->new_sailor(@{$self->{mode_opt}}, @_);
    return $sailor->flag_gif($s . "\x44", @{$self->{mode_opt}}, @_);
  }

  sub generate_sav {
    my $self = shift;
    my $J = $self->{j};
    my $s = shift;
    my @opt= @_;
    my %opt
      = (
	 trl => $self->{trl},
	 @{$self->{mode_opt}},
	 @_
	);
    if (defined $opt{trl} && exists $self->{sav_default}->{$opt{trl}}) {
      @opt = (@{$self->{sav_default}->{$opt{trl}}}, @opt);
    }
    return $J->generate_sav($s, @{$self->{mode_opt}}, @opt);
  }

  sub process_arguments {
    my $self = shift;
    my @args = @_;

    my $main_mode;
    my $gif_mode = 0;
    my $trl = undef;
    my $flag_gif_opt = 0;
    my $text_gif_opt = 0;
    my $sav_opt = 0;
    my $ngb_init = undef;;
    my @mode_opt;
    my $output = undef;

    $main_mode = "encode";
    if (@args != 0) {
      my $c = $args[0];
      if ($c eq "-t" || $c eq "--translit") {
	shift(@args);
	$main_mode = "translit_encode";
	if (@args > 0) {
	  $c = $args[0];
	  if ($c eq "-c" || $c eq "--encode") {
	    shift(@args);
	  } elsif ($c eq "-u" || $c eq "--decode") {
	    shift(@args);
	    $main_mode = "translit_decode";
	  }
	}
      } elsif ($c eq "-c" || $c eq "--encode") {
	shift(@args);
      } elsif ($c eq "-u" || $c eq "--decode") {
	shift(@args);
	$main_mode = "decode";
      } elsif ($c eq "-n" || $c eq "--raw") {
	shift(@args);
	$main_mode = "text";
      } elsif ($c eq "--sav") {
	shift(@args);
	$main_mode = "sav";
      } elsif ($c eq "--rom") {
	shift(@args);
	$main_mode = "rom";
      }
    }

    Getopt::Long::Configure("posix_default", "auto_version",
			    "no_ignore_case", "gnu_compat");
    Getopt::Long::GetOptionsFromArray
       (\@args,
	"console-encoding=s" => \$Resource::CONSOLE_ENCODING,
	"filename-encoding=s" => \$Resource::FILENAME_ENCODING,
	"o|output=s" => \$output,
	"T|trl=s"  => \$trl,
	"trl-init=s"  => \$ngb_init,
	"flag-gif"  => \$flag_gif_opt,
	"text-gif"  => \$text_gif_opt,
	"sav"  => \$sav_opt,
	"g"  => \$gif_mode,
	"D|define=s@" => \@mode_opt,
	"man" => sub {pod2usage(-verbose => 2)},
	"h|?" => sub {pod2usage(-verbose => 0, -output=>\*STDOUT, 
				-exitval => 1)},
	"help" => sub {pod2usage(1)},
       ) or pod2usage(-verbose => 0);
    for (my $i = 0; $i < @args; $i++) {
      $args[$i] = decode_con($args[$i]);
    }
    my @r;
    foreach my $kv (@mode_opt) {
      my ($k, $v) = split(/[= ]/, decode_con($kv), 2);
      if (defined $v) {
	push(@r, $k, $v);
      } else {
	push(@r, $k, 1);
      }
    }
    @mode_opt = @r;

    $gif_mode = "F" if $flag_gif_opt;
    $gif_mode = "T" if $text_gif_opt;
    if ($flag_gif_opt && $main_mode ne "encode" && $main_mode ne "text") {
      die "--flag-gif must be used with -c or -n .";
    }
    if ($text_gif_opt && $main_mode ne "decode" && $main_mode ne "text"
	&& $main_mode ne "translit_decode" && $main_mode ne "translit_encode") {
      die "--text-gif must be used with -u or -n or -t -u .";
    }
    if ($gif_mode && $main_mode eq "encode") {
      $gif_mode = "F";
    }
    if ($gif_mode && $main_mode =~ /decode/) {
      $gif_mode = "T";
    }
    if ($gif_mode && $gif_mode ne "T" && $gif_mode ne "F") {
      $gif_mode = "T";
    }
    $gif_mode = "S" if $sav_opt;

    die "Too many arguments." if @args > 1;

    $self->{main_mode} = $main_mode;
    $self->{output_mode} = $gif_mode;
    $self->{trl} = decode_con($trl) if defined $trl;
    $self->{mode_opt} = \@mode_opt;
    $self->{output} = decode_con($output) if defined $output;
    $self->{input} = $args[0] if @args;

    if (defined $ngb_init) {
      my $fn = decocde_con($ngb_init);
      open(my $fh, "<", encode_fn($fn))	or die "$fn: $!";
      my $self->{ngb_init_string} = join("", <$fh>);
      close($fh);
    }
  }

  sub command_loop {
    my $self = shift;
    my $J = $self->{j};
    my $T = $self->{translit};
    my $main_mode = $self->{main_mode};
    my $output_mode = $self->{output_mode};

    STDOUT->autoflush(1);
    binmode(STDERR, ":" . $Resource::CONSOLE_ENCODING);

    my $rawinput;
    if (! grep {$main_mode eq $_} qw(rom)) {
      if (defined $self->{input}) {
	my $fn = $self->{input};
	open(my $fh, "<", encode_fn($fn)) or die "$fn: $!";
	binmode($fh, ":raw");
	$rawinput = join("", <$fh>);
	close($fh);
      } else {
	binmode(STDIN, ":raw");
	$rawinput = join("", <STDIN>);
      }
    }

    my $output;
    if ($main_mode eq "encode") {
      $output = $self->encode_raw($rawinput);
    } elsif ($main_mode eq "decode") {
      $output = $self->decode_raw($rawinput);
    } elsif ($main_mode eq "translit_encode") {
      $output = $self->translit_encode_raw($rawinput);
    } elsif ($main_mode eq "translit_decode") {
      $output = $self->translit_decode_raw($rawinput);
    } elsif ($main_mode eq "text") {
      $output = $rawinput;
    } elsif ($main_mode eq "sav") {
      $output = $self->generate_sav_raw($rawinput);
    } else {
      die "$main_mode: Future Work!";
    }

    if ($output_mode) {
      if ($output_mode eq "S") {
	$output = $self->generate_sav_raw($output);
      } elsif ($output_mode eq "F") {
	$output = $self->flag_gif_raw($output);
      } else {
	$output = $self->text_gif_raw($output);
      }
    }
    if (defined $self->{output}) {
      my $fn = $self->{output};
      open(my $fh, ">", encode_fn($fn)) or die "$fn: $!";
      binmode($fh, ":raw");
      print $fh $output;
      close($fh);
    } else {
      binmode(STDOUT, ":raw");
      print $output;
    }
    exit(0);
  }

  sub encode_raw {
    my $S = shift; my $s = shift; 
    return $S->encode(decode_u($s), @_);
  }
  sub decode_raw {
    my $S = shift; my $s = shift; 
    return encode_u($S->decode($s, @_));
  }
  sub translit_encode_raw {
    my $S = shift; my $s = shift; 
    return encode_u($S->translit_encode(decode_u($s), @_));
  }
  sub translit_decode_raw {
    my $S = shift; my $s = shift; 
    return encode_u($S->translit_decode(decode_u($s), @_));
  }
  sub text_gif_raw {
    my $S = shift; my $s = shift; 
    return $S->text_gif(decode_u($s), @_);
  }
  sub flag_gif_raw {
    my $S = shift; my $s = shift; 
    return $S->flag_gif($s, @_);
  }
  sub generate_sav_raw {
    my $S = shift; my $s = shift; 
    return $S->generate_sav(decode_u($s), @_);
  }

 ClassInit:
  {
    $GIF_FONT{"nes8x8"} = GifFont::JRFSemaphoreRom->new
      (nes => 0,
       a => "FF61-FF9F:A1", a => "FFE5:A0",  # japanese hwkata.
       a => "5D0-5EA:FD-E3", a => "5C3:E2",  # hebrew.
       a => "5BC:E1", a => "20AA:E0",
      );
    $GIF_FONT{"nes8x8_rtol"} = GifFont::JRFSemaphoreRom->new
      (nes => 0, direction => "right-to-left",
       a => "FF61-FF9F:A1", a => "FFE5:A0",
       a => "5D0-5EA:FD-E3", a => "5C3:E2",
       a => "5BC:E1", a => "20AA:E0",
      );
    $GIF_FONT{"nes8x16a"} = GifFont::JRFSemaphoreRom->new
      (nes => 1, size => "8x16",
       a => "FF61-FF9F:A1", a => "FFE5:A0",
       a => "5D0-5EA:FD-E3", a => "5C3:E2",
       a => "5BC:E1", a => "20AA:E0",
      );
    $GIF_FONT{"nes8x16b"} = GifFont::JRFSemaphoreRom->new
      (nes => 3, size => "8x16",
       a => "FF61-FF9F:A1", a => "FFE5:A0",
       a => "5D0-5EA:FD-E3", a => "5C3:E2",
       a => "5BC:E1", a => "20AA:E0",
      );
    $GIF_FONT{"nes8x16b_rtol"} = GifFont::JRFSemaphoreRom->new
      (nes => 3, size => "8x16", d => "r-to-l",
       a => "FF61-FF9F:A1", a => "FFE5:A0",
       a => "5D0-5EA:FD-E3", a => "5C3:E2",
       a => "5BC:E1", a => "20AA:E0",
      );
    $GIF_FONT{"j0heb.nes"} = $GIF_FONT{"nes8x8_rtol"};
    $GIF_FONT{"j0ja.hw"} = $GIF_FONT{"nes8x8"};
    $GIF_FONT{"ascii"} = $GIF_FONT{"nes8x8"};
    $GIF_FONT{"alpha"} = $GIF_FONT{"nes8x8"};
    $SAV_DEFAULT{"j0heb.nes"}
      = [righttoleft => 1, toprintable => 0, font => 5];
    $SAV_DEFAULT{"j0ja.hw"} = [toprintable => 0];
  }
}

1;
