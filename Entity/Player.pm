#!/usr/bin/perl
package Entity::Player;
use strict;
use warnings;
use SDL;
use SDL::Event;
use SDL::Events;
use SDLx::App;
use SDL::GFX::Rotozoom;
use SDLx::Sprite;


# Programmer: DaleG
# Movement of first hero
# module for neilR base program

my $character;
my @position;
my @direction;
@direction = (0, 0);
my $keyMove;

my @playerSprites;
my $offset;

sub initPlayer {
  my $sprites=shift;
  my $pos=shift;
  $offset = shift;
  foreach my $i (0 .. $#$sprites) {
    print "Loading image: $$sprites[$i]\n";
    my $img = SDL::Image::load( $$sprites[$i]) or die SDL::get_error;
    $playerSprites[$i] = $img;
    #$playerSprites[$i] = SDL::GFX::Rotozoom::surface( $img, 0, 2, SMOOTHING_OFF );
    print "Successfully loaded image\n";
  }
  $character = SDLx::Sprite->new(surface=>$playerSprites[0]);
  @position = @$pos;
}

sub doPlayerEvents {
  my ($event, $app) = @_;
  my $type = $event->type();
  if ($type == SDL_KEYDOWN) {
    my $key = $event->key_sym;
    if ($key == SDLK_a) {
      $keyMove = 1;
      $direction[0] = -1;
      $direction[1] = 0;
    }
    if ($key == SDLK_d) {
      $keyMove = 1;
      $direction[0] = 1;
      $direction[1] = 0;
    }
    if ($key == SDLK_w) {
      $keyMove = 1;
      $direction[1] = -1;
      $direction[0] = 0;
    }
    if ($key == SDLK_s) {
      $keyMove = 1;
      $direction[1] = 1;
      $direction[0] = 0;
    }
  }
}

sub movePlayer { 
  my ($step, $app, $t) = @_;
  $position[0] += $direction[0] if $keyMove;
  $position[1] += $direction[1] if $keyMove;
  $keyMove = 0;
}

sub showPlayer {
  my ($s, $app) = @_;
  my $surface = ($direction[1] == 1 ? $playerSprites[0] :
                ($direction[1] == -1 ? $playerSprites[3] :
                ($direction[0] == 1 ? $playerSprites[2] :
                ($direction[0] == -1 ? $playerSprites[1] : $playerSprites[0])))); 
  $character->surface($surface);
  $character->x (((800/2)-(14))+(($position[0] * 14) -($position[1] * 14)) - $offset);
  print $character->x . "\n";
  $character->y ((($position[0] + $position[1]) * 7) - 14);
  $character->draw($app);
}
return 1;
