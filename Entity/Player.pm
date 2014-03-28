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

use Entity::data ':all';
# Programmer: DaleG
# Movement of first hero
# module for neilR base program

our ($roomArea, @room, %resolution, @playerPos);

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
    #print "[$position[0]][$position[1]]\n"; 
    #print "[$room[$position[0]][$position[1]]]\n";
    my $destChar;
    if ($key == SDLK_a) {
      $destChar=$room[$position[0]-1][$position[1]];
      if ($destChar eq "#") {
        return;
      }
      if ($destChar eq "a") {
        return;
      }
       if ($destChar eq "h") {
        return;
      }
       if ($destChar eq "b") {
        return;
      }
      if ($destChar eq "E") {
        return;
      }
      if ($destChar eq "G") {
        return;
      }
      if ($destChar eq "w") {
        return;
      }      
      $keyMove = 1;
      # change to x
      $direction[0] = -1;
      # change to y
      $direction[1] = 0;
    }
    if ($key == SDLK_d) {
      $destChar=$room[$position[0]+1][$position[1]];
      if ($destChar eq "#") {
        return;
      }
      if ($destChar eq "a") {
        return;
      }
       if ($destChar eq "h") {
        return;
      }
      if ($destChar eq "b") {
        return;
      }
      if ($destChar eq "E") {
        return;
      }
      if ($destChar eq "G") {
        return;
      }
      if ($destChar eq "w") {
        return;
      }
      $keyMove = 1;
      $direction[0] = 1;
      $direction[1] = 0;
    }
    if ($key == SDLK_w) {
      $destChar=$room[$position[0]][$position[1]-1];
      if ($destChar eq "#") {
        return;
      }
      if ($destChar eq "a") {
        return;
      }
      if ($destChar eq "h") {
        return;
      }
      if ($destChar eq "b") {
        return;
      }
      if ($destChar eq "E") {
        return;
      }
      if ($destChar eq "G") {
        return;
      }
      if ($destChar eq "w") {
        return;
      }   
      $keyMove = 1;
      $direction[1] = -1;
      $direction[0] = 0;
    }
    if ($key == SDLK_s) {
      $destChar=$room[$position[0]][$position[1]+1];
      if ($destChar eq "#") {
        return;
      }
      if ($destChar eq "a") {
        return;
      }
      if ($destChar eq "h") {
        return;
      }
      if ($destChar eq "b") {
        return;
      }
      if ($destChar eq "E") {
        return;
      }
      if ($destChar eq "G") {
        return;
      }
      if ($destChar eq "w") {
        return;
      }   
      $keyMove = 1;
      $direction[1] = 1;
      $direction[0] = 0;
    }
  }
}

sub movePlayer { 
  my ($step, $app, $t) = @_;
  
if ($room[$position[0]+$direction[0]][$position[1]+$direction[1]] eq "E"){
      $keyMove = 0 ;
    }
  if ($keyMove) {
    $room[$position[0]][$position[1]] = ".";
    $position[0] += $direction[0];
    $position[1] += $direction[1];
    @playerPos = @position; #make sure that our player-centering code works
    $room[$position[0]][$position[1]] = "p";
    $keyMove = 0;
  }
}

sub showPlayer {
  my ($s, $app) = @_;
  my $surface = ($direction[1] == 1 ? $playerSprites[0] :
                ($direction[1] == -1 ? $playerSprites[3] :
                ($direction[0] == 1 ? $playerSprites[2] :
                ($direction[0] == -1 ? $playerSprites[1] : $playerSprites[0])))); 
  $character->surface($surface);
  $character->x ((($resolution{'width'}/2)-(14))+((0 * 14) -(0* 14)) - $offset);
  #print $character->x . "\n";
  $character->y (((0 * 7) - 14) + $resolution{'height'} / 2);
  $character->draw($app);
}
return 1;
