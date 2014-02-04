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

my $character;
my @position;
my @direction;
@direction = (1, 0);
my $keyMove;

my @EnemySprites;
my $offset;

sub initEnemy {
  my $sprites=shift;
  my $pos=shift;
  $offset = shift;
  foreach my $i (0 .. $#$sprites) {
    print "Loading image: $$sprites[$i]\n";
    my $img = SDL::Image::load( $$sprites[$i]) or die SDL::get_error;
    $EnemySprites[$i] = $img;
    #$EnemySprites[$i] = SDL::GFX::Rotozoom::surface( $img, 0, 2, SMOOTHING_OFF );
    print "Successfully loaded image\n";
  }
  $character = SDLx::Sprite->new(surface=>$EnemySprites[0]);
  @position = @$pos;
}

sub doEnemyEvents {
  my ($event, $app) = @_;
  my $type = $event->type();
  # object dection for enemy
  if ($type == SDL_KEYDOWN) {
    print $room[$position[0] + $direction[0]][$position[1]] . "\n";
    if (($room[$position[0] + $direction[0]][$position[1]] eq "#") or 
        ($room[$position[0] + $direction[0]][$position[1]] eq "w") or
        ($room[$position[0] + $direction[0]][$position[1]] eq "p")) {
      $direction[0] = $direction[0] * -1;
    }
    $keyMove = 1;
  }
}

sub moveEnemy { 
  my ($step, $app, $t) = @_;
  $position[0] += $direction[0] if $keyMove;
  $position[1] += $direction[1] if $keyMove;
  $keyMove = 0;
}

sub showEnemy {
  my ($s, $app) = @_;
  my $surface = ($direction[1] == 1 ? $EnemySprites[0] :
                ($direction[1] == -1 ? $EnemySprites[3] :
                ($direction[0] == 1 ? $EnemySprites[2] :
                ($direction[0] == -1 ? $EnemySprites[1] : $EnemySprites[0])))); 
  $character->surface($surface);
  $character->x (((800/2)-(14))+(($position[0] * 14) -($position[1] * 14)) - $offset);
  #print $character->x . "\n";
  $character->y ((($position[0] + $position[1]) * 7) - 14);
  $character->draw($app);
}
return 1;
