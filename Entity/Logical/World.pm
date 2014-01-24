#!/usr/bin/perl
use strict;
use warnings;
package Entity::Logical::World;

sub createWorld {
  my ($img, $ents) = @_;
  my $return;
  my $offset = ((800/2)-14) - ($img->h())*14;
  for my $x (0 .. $img->w()) {
    for my $y (0 .. $img->h()) {
      my $val = $img->[$x][$y];
      my $dstx = (((800/2) - 14) + ($x*14 - $y*14)) - $offset;
      my $dsty = ($x+$y)*7;
      if (grep(/^$val$/, keys %$ents)) {
        &{${$ents}{$val}}($dstx,$dsty);
      }
    }
  }
}
return 1;
