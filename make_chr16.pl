#!/usr/bin/perl
#require 5.008;
our $VERSION = "0.01"; #Time-stamp: <2014-03-06T22:24:44Z>

## License:
##
##   I in a provincial state made this program intended to be public-domain. 
##   But it might be better for you like me to treat this program as such 
##   under the BSD-License or under the Artistic License.
##
##   Within three months after the release of this program, I
##   especially admit responsibility of effort for rational request of
##   correction to this program.
##
## Author's Link:
##
##   http://jrf.cocolog-nifty.com/software/
##   (The page is written in Japanese.)
##

use strict;
use warnings;
use utf8; # Japanese English

use Encode;

our $CHR = "jrf_semaphore.chr";
our $CHR16A = "jrf_semaphore16a.chr";
our $CHR16B = "jrf_semaphore16b.chr";

MAIN:
{
  open(my $fh, "<", $CHR) or die ("$CHR: $!");
  binmode($fh, ":raw");
  my $s = join("", <$fh>);
  close($fh);
  my @src = unpack("C*", $s);
  my @dest;
  for (my $i = 0; $i < 0x20; $i++) {
    my $saddr = $i * 16;
    my $daddr = $i * 16;
    my @chr = @src[$saddr .. ($saddr + 15)];
    @dest[$daddr .. ($daddr + 15)] = @chr;
  }
  for (my $i = 0; $i < 0x20; $i++) {
    my $saddr = ($i + 0x80) * 16;
    my $daddr = ($i + 0x20) * 16;
    my @chr = @src[$saddr .. ($saddr + 15)];
    @dest[$daddr .. ($daddr + 15)] = @chr;
  }
  for (my $i = 0x20; $i < 0x80; $i++) {
    my $saddr = $i * 16;
    my $daddr1 = ($i + ($i & 0xf0)) * 16;
    my $daddr2 = ($i + ($i & 0xf0) + 0x10) * 16;
    @dest[$daddr1 .. ($daddr1 + 15), $daddr2 .. ($daddr2 + 15)]
      = (0) x 32;
    @dest[($daddr1 + 4) .. ($daddr1 + 7), ($daddr1 + 12) ..($daddr1 + 15)]
      = @src[$saddr .. ($saddr + 3), ($saddr + 8) .. ($saddr + 11)];
    @dest[($daddr2 + 0) .. ($daddr2 + 3), ($daddr2 + 8) ..($daddr2 + 11)]
      = @src[($saddr + 4) .. ($saddr + 7), ($saddr + 12) .. ($saddr + 15)];
  }
  if (1) {
    my $i = 0;
    my $saddr = $i * 16;
    my $daddr = ($i + 0x10) * 16;
    my @chr = @src[$saddr .. ($saddr + 15)];
    @dest[$daddr .. ($daddr + 15)] = @chr;
  }
  open($fh, ">", $CHR16A), or die "$CHR16A: $!";
  binmode($fh, ":raw");
  print $fh pack("C*", @dest);
  close($fh);

  @src = unpack("C*", $s);
  for (my $i = 0xa0; $i < 0xFE; $i++) {
    my $j = 0xff & ($i + ($i & 0xf0) + 0x10);
    $j = 0xff - $j if ($j & 0x80);
    my $saddr = $i * 16;
    my $daddr1 = ($j + ($j & 0xf0)) * 16;
    my $daddr2 = ($j + ($j & 0xf0) + 0x10) * 16;
    @dest[$daddr1 .. ($daddr1 + 15), $daddr2 .. ($daddr2 + 15)]
      = (0) x 32;
    @dest[($daddr1 + 4) .. ($daddr1 + 7), ($daddr1 + 12) ..($daddr1 + 15)]
      = @src[$saddr .. ($saddr + 3), ($saddr + 8) .. ($saddr + 11)];
    @dest[($daddr2 + 0) .. ($daddr2 + 3), ($daddr2 + 8) ..($daddr2 + 11)]
      = @src[($saddr + 4) .. ($saddr + 7), ($saddr + 12) .. ($saddr + 15)];
  }
  if (1) {
    my $saddr = 0x10 * 16;
    my $daddr = 0x11 * 16;
    my @chr = @src[$saddr .. ($saddr + 15)];
    @dest[$daddr .. ($daddr + 15)] = @chr;
  }
  if (1) {
    my $i = 0;
    my $saddr = $i * 16;
    my $daddr = ($i + 0x10) * 16;
    my @chr = @src[$saddr .. ($saddr + 15)];
    @dest[$daddr .. ($daddr + 15)] = @chr;
  }
  open($fh, ">", $CHR16B), or die "$CHR16B: $!";
  binmode($fh, ":raw");
  print $fh pack("C*", @dest);
  close($fh);
}
