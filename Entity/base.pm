#!/usr/bin/perl
use strict;
use warnings;

package baseEntity;

sub new {
  my $class = shift;
  my %self = {
    name => 'MISSING ENTITY', #Entity name, for debugging
    icon => '?',              #Icon for the ent in textspace
    sprite => '',             #Render sprite for the entity
  }
  return bless(%self, $class);
}

sub onThink {
  my $self = shift;
  return 0;
}

sub onAttacked {
  my $self = shift;
  return 0;
}

sub onAttack {
  my $self = shift;
  return 0;
}

return 1;
