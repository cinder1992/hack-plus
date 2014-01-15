#!/usr/bin/perl
use strict
use warnings
package Entity::Logical::eventHandle;

sub new {
  my $self = {
    _handles => [],
    _linkedHandles => [],
    _
