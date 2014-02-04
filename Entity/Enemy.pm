#!/usr/bin/perl
package Entity::Enemy;
use strict;
use warnings;
use SDL;
use SDL::Event;
use SDL::Events;
use SDLx::App;
use SDL::GFX::Rotozoom;
use SDLx::Sprite;

use Entity::data ':all';
# Programmer: DaleG
# Movement of Enemy
# module for neilR base program

our ($roomArea, @room);

sub new {
  my $classname = shift;
  my $sprites = shift;
  my $self = {
    _sprites => [], 
    _pos => shift, 
    _offset => shift,
    _dir => [1, 0], 
    _surface => 0,
    _canMove => 0
  };

  my $app = shift;

  foreach my $i (0 .. $#$sprites) {
    print "Loading image: $$sprites[$i]\n";
    my $img = SDL::Image::load( $$sprites[$i]) or die SDL::get_error;
    $self->{_sprites}[$i] = $img;
    #$EnemySprites[$i] = SDL::GFX::Rotozoom::surface( $img, 0, 2, SMOOTHING_OFF );
    print "Successfully loaded image\n";
  }
  $self->{_surface} = SDLx::Sprite->new(surface=>$self->{_sprites}[0]);
  bless ($self, $classname);
  $app->add_event_handler(sub{$self->doEnemyEvents(@_)});
  $app->add_move_handler(sub{$self->moveEnemy(@_)});
  $app->add_show_handler(sub{$self->showEnemy(@_)});
  return $self;
}

sub doEnemyEvents {
  my ($self, $event, $app) = @_;
  my $type = $event->type();
  # object dection for enemy
  if ($type == SDL_KEYDOWN) {
    print "Position: [$self->{_pos}[0],$self->{_pos}[1]]: " . $room[$self->{_pos}[0] + $self->{_dir}[0]][$self->{_pos}[1]] . "\n";
    if (($room[$self->{_pos}[0] + $self->{_dir}[0]][$self->{_pos}[1]] eq "#") or 
        ($room[$self->{_pos}[0] + $self->{_dir}[0]][$self->{_pos}[1]] eq "w")) {
      $self->{_dir}[0] = $self->{_dir}[0] * -1;
    }
    $self->{_canMove} = 1;
  }
}
 
sub moveEnemy { 
  my ($self, $step, $app, $t) = @_;
  $self->{_pos}[0] += $self->{_dir}[0] if $self->{_canMove};
  $self->{_pos}[1] += $self->{_dir}[1] if $self->{_canMove};
  $self->{_canMove} = 0;
}

sub showEnemy {
  my ($self, $s, $app) = @_;
  my $surface = ($self->{_dir}[1] == 1 ? $self->{_sprites}[0] :
                ($self->{_dir}[1] == -1 ? $self->{_sprites}[3] :
                ($self->{_dir}[0] == 1 ? $self->{_sprites}[2] :
                ($self->{_dir}[0] == -1 ? $self->{_sprites}[1] : $self->{_sprites}[0])))); 
  $self->{_surface}->surface($surface);
  $self->{_surface}->x (((800/2)-(14))+(($self->{_pos}[0] * 14) -($self->{_pos}[1] * 14)) - $self->{_offset});
  $self->{_surface}->y ((($self->{_pos}[0] + $self->{_pos}[1]) * 7) - 14);
  $self->{_surface}->draw($app);
}
return 1;
