#!/usr/bin/perl
#require 5.008_003;
{ package main;
  my $TS = 'Time-stamp: <2020-01-24T03:00:15Z>';
  $TS =~ s/Time-stamp\:\s+<(.*)>/$1/;
  my $AUTHOR = "JRF (http://jrf.cocolog-nifty.com/)";
  our $VERSION = "0.16; jrf_semaphore.pl; last modified at $TS; by $AUTHOR";
  our $DEBUG = 1;
}

## License:
##
##   The author is a Japanese.
##
##   I intended this program to be public-domain, but you can treat
##   this program under the (new) BSD-License or under the Artistic
##   License, if it is convenient for you.
##
##   Within three months after the release of this program, I
##   especially admit responsibility of efforts for rational requests
##   of correction to this program.
##
##   I often have bouts of schizophrenia, but I believe that my
##   intention is legitimately fulfilled.
##
## Author's Link:
##
##   http://jrf.cocolog-nifty.com/software/
##   (The page is written in Japanese.)
##

use strict;
use warnings;
#no autovivification qw(strict warn fetch exists delete store);
use utf8; # Japanese English

{
  package main;

  use FindBin;
  use File::Spec;
  use lib File::Spec->catdir($FindBin::Bin, 'lib');
  use lib File::Spec->catdir($FindBin::Bin, 'ngb_lib');
}

{
  package Resource;

  use FindBin qw($Bin);
  use File::Spec::Functions qw(catfile catdir);
  use JRF::Resource;

  BEGIN{
    our @RESOURCE_PATH = (#".", "./trl",
			  catfile($ENV{HOME}, ".naggy-backend"),
			  catfile($ENV{HOME}, ".trl_init"),
			  $Bin,
			  catdir($Bin, "trl"),
			  catdir($Bin, "nginit"),
			  "/usr/share/misc/jrf_semaphore", # Default.
			  "/usr/share/jrf_semaphore", # Alternative.
			 );
    our $CONSOLE_ENCODING = "utf8";
    our $FILENAME_ENCODING = "utf8";
    our $SEMAPHORE_ASM = "jrf_semaphore.asm";
    our $SEMAPHORE_NES_ROM = "jrf_semaphore.nes";
  }
}

## See below to know the object-oriented techniques of this program:
##
##   《Perl でオブジェクト指向 Ｃ＋＋風 その３ ローカル関数》
##   http://jrf.cocolog-nifty.com/software/2011/01/post-1.html
##

{
  package Resource;
  use GD::simple;

  our %COLOR_NAME_LC;

 ModuleInit:
  {
    BEGIN {
      my $cn = GD::Simple->color_names();
      foreach my $k (keys %$cn) {
	my $v = $cn->{$k};
	$COLOR_NAME_LC{lc($k)} = $v;
      }
    }
  }
}

MAIN:
if (! defined $main::IN_TEST || ! $main::IN_TEST)
{
  package Main;

  # To process ClassInits in the right order,
  # use JRF::FlagSemaphore at first.
  use JRF::FlagSemaphore;
  use JRF::FlagSemaphore::Command;

  if (@ARGV > 0 &&
      ($ARGV[0] eq "--naggy-backend" || $ARGV[0] eq "--ngb")) {
    shift(@ARGV);
    require Naggy::Backend;
    my $JC = JRF::FlagSemaphore::Command->new();
    my $N = Naggy::Backend::Command->new(@ARGV);
    my $ngb = $N->{backend};
    $JC->{ngb} = $ngb;
    $JC->init_naggy_backend();
    $JC->{ngb}->{command}->{"trl-init"}->{allow_trl_init} = 1;
    $N->command_loop();
  } else {
    my $JC = JRF::FlagSemaphore::Command->new();
    $JC->process_arguments(@ARGV);
    $JC->command_loop();
  }
}

BEGIN {
    $ENV{"PERLDOC"} = "" if ! exists $ENV{"PERLDOC"};
    $ENV{"PERLDOC"} .= " " if $ENV{"PERLDOC"} ne "";
    $ENV{"PERLDOC"} .= "-wcenter:'JRF Flag Semaphore Command Manual'";
}

=pod

=head1	NAME

jrf_samephore.pl - the encoding/decoding program of a flag semaphore.

=head1	SYNOPSIS

B<jrf_semaphore.pl> -c [-T TRL_NAME] [--flag-gif|-g] INPUT_FILE

B<jrf_semaphore.pl> -u [-T TRL_NAME] [--text-gif|-g|--sav] INPUT_FILE

B<jrf_semaphore.pl> -t -c [-T TRL_NAME] [--sav] INPUT_FILE

B<jrf_semaphore.pl> -t -u [-T TRL_NAME] [--text-gif|-g|--sav] INPUT_FILE

B<jrf_semaphore.pl> -n [--flag-gif|--text-gif] INPUT_FILE

B<jrf_semaphore.pl> --sav [-T TRL_NAME] INPUT_FILE

=head1	Options

=over 8

=item B<--help>

shows help message about options.

=item B<--man>

shows man page.

=item B<--version>

shows version infomation.

=item B<-c>

encoding mode. default.

=item B<-u>

decoding mode.

=item B<-t> or B<--translit>

transliteration only.

=item B<-n> or B<--raw>

no encoding. no decoding. no transliteration. but output.

=item B<--sav>

output .SAV file for jrf_semaphore.nes .

=item B<-o> F<OUTPUT> or B<--output> F<OUTPUT>

specifies a filename of output.

=item B<-T> F<TABLE_NAME> or B<--trl> F<TABLE_NAME>

specifies a table name of transliteration.

This is a test version.  You can specify only j0heb.nes or j0ja.hw .

=item B<--flag-gif> or B<-g>

output gif animation of the flag code.

=item B<--text-gif> or B<-g>

output text as a gif.

=item B<--console-encoding> F<encoding>

specifies the encoding for console arguments.

=item B<--filename-encoding> F<encoding>

specifies the encoding for filenames.

=item B<-D> F<opt>=F<value>

specifies a mode option.

=back

=head1	DESCRIPTION

B<This program> is the encoding or decoding program of a flag
semaphore which is originally implemented for NES emulators.

=head1 EXAMPLE

$ echo -n br\'syt | perl jrf_semaphore.pl -t -c -T j0heb.nes \
    | perl jrf_semaphore.pl -c -T j0heb.nes \
    | perl jrf_semaphore.pl -u --text-gif > test.gif

$ echo -n "This is a test." \
    | perl jrf_semaphore.pl -c --flag-gif -o test2.gif

If you have copied tankanji.txt, tankanji.txt.sdb.dir,
taknanji.txt.sdb.pag, SKK-JISYO.L, SKK-JISYO.L.sdb.dir,
SKK-JISYO.L.sdb.pag, bushu-skk-dic.txt, bushu-skk-dic.txt.sdb.dir and
bushu-skk-dic.txt.sdb.pag from the working quail-naggy directory, you
can use Japanese conversion via -T naggy like below.

$ echo -n "koreha,h. English,a."\
    "majirino,h.nihongo,j.no,h.tesuto,k.desu.,h." \
    "[,h.atui,j,,.natu,J,m..],h." \
    | perl jrf_semaphore.pl -t -c -T naggy

This outputs: これは English まじりの日本語のテストです。 「暑い夏。」
(means "This is a test of Japanese mixed with English. 'Hot Summer.'")

=head1	AUTHORS

JRF E<lt>http://jrf.cocolog-nifty.com/softwareE<gt>

=head1	COPYRIGHT

Copyright 2014, 2017 by JRF L<http://jrf.cocolog-nifty.com/software/>

The author is a Japanese.

I intended this program to be public-domain, but you can treat
this program under the (new) BSD-License or under the Artistic
License, if it is convenient for you.

Within three months after the release of this program, I
especially admit responsibility of efforts for rational requests
of correction to this program.

I often have bouts of schizophrenia, but I believe that my
intention is legitimately fulfilled.

=head1	SEE ALSO

L<Encode>

=cut
