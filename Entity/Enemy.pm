#!/usr/bin/perl
package Entity::Enemy;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(createEnemy);
use strict;
use warnings;
use SDL;
use SDL::Event;
use SDL::Events;
use SDLx::App;
use SDL::GFX::Rotozoom;
use SDLx::Sprite;



use Entity::data ':all';  #Load the world data so we can check everything
# Programmer: DaleG
# Movement of Enemy
# module for neilR base program

our $tick;
our %resolution;
our @playerPos;

our ($roomArea, @room); #world data
my $death = SDLx::Sprite->new( image => "img/death_screen.png" ) or die("Could not load death image!");

sub createEnemy {
  my $sprites = shift;
  my $self = {        #Define our local variables
    _sprites => [],   #Sprite surfaces
    _pos => shift,    #Position
    _offset => shift, #Offset
    _dir => [1, 0],   #Initial direction
    _surface => 0,    #Drawing surface
    _canMove => 0,    #Can we move?
    _complexPath => shift #do we follow a complex path?
  };

  my $app = shift;

  foreach my $i (0 .. $#$sprites) { #Fill the sprites array
    print "Loading image: $$sprites[$i]\n"; #Debug statement
    my $img = SDL::Image::load( $$sprites[$i]) or die SDL::get_error; #Die if we can't load our image
    $self->{_sprites}[$i] = $img; #Put the sprite into the array
    #$EnemySprites[$i] = SDL::GFX::Rotozoom::surface( $img, 0, 2, SMOOTHING_OFF );
    print "Successfully loaded image\n"; #If we got here, we're done.
  }
  $self->{_surface} = SDLx::Sprite->new(surface=>$self->{_sprites}[0]); #Create the sprite object

  $app->add_event_handler(sub{doEnemyEvents($self, @_)}); #Register event handlers
  $app->add_move_handler(sub{moveEnemy($self, @_)});
  #$app->add_show_handler(sub{showEnemy($self, @_)});

  return $self;
}

sub doEnemyEvents {
  my ($self, $event, $app) = @_;
  my $type = $event->type();
  # object dection for enemy
}


 
sub moveEnemy {
  my ($self, $step, $app, $t) = @_;
    if ($tick) {
    #print "Position: [$self->{_pos}[0],$self->{_pos}[1]]: " . $room[$self->{_pos}[0] + $self->{_dir}[0]][$self->{_pos}[1]] . "\n";
    my $collided = 1;
    if ($self->{_complexPath} == 1) {
      while ($collided) {
        my $posChar = $room[$self->{_pos}[0] + $self->{_dir}[0]][$self->{_pos}[1] + $self->{_dir}[1]];
        if ($posChar eq 'w' or
            $posChar eq '#' or
            $posChar eq 'd' or
            $posChar eq 'u' or
            $posChar eq 'h' or
            $posChar eq 'b' or
            $posChar eq 'a' or
            $posChar eq 'G' or
            $posChar eq 'E') {
          my @tempDir = (0 + ($self->{_dir}[1] * -1), $self->{_dir}[0]);
          $self->{_dir} = \@tempDir;
        }
        else {
          $collided = 0;
        }
      }
    }
    else {
      my $posChar = $room[$self->{_pos}[0] + $self->{_dir}[0]][$self->{_pos}[1] + $self->{_dir}[1]];
      if ($posChar eq 'w' or
          $posChar eq '#' or
          $posChar eq 'd' or
          $posChar eq 'u' or
          $posChar eq 'h' or
          $posChar eq 'b' or
          $posChar eq 'a' or
          $posChar eq 'G' or
          $posChar eq 'E') {
        my @tempDir = (($self->{_dir}[0] * -1), $self->{_dir}[1]);
        $self->{_dir} = \@tempDir;
      }
    }
    if ($room[$self->{_pos}[0] + $self->{_dir}[0]][$self->{_pos}[1]] eq "p") {
      $self->{_canMove} = 0;
    } else {
      $self->{_canMove} = 1;
    }
  }
  if ($room[$self->{_pos}[0] + $self->{_dir}[0]][$self->{_pos}[1] + $self->{_dir}[1]] eq "p") {
    &main::death();
  }
  if ($self->{_canMove}) {  
    $room[$self->{_pos}[0]][$self->{_pos}[1]] = ".";
    $self->{_pos}[0] += $self->{_dir}[0];
    $self->{_pos}[1] += $self->{_dir}[1];
    $room[$self->{_pos}[0]][$self->{_pos}[1]] = "E";
    $self->{_canMove} = 0;
  }
}

sub showEnemy {
  my ($self, $s, $app) = @_;
  my $xPos = $self->{_pos}[0] - $playerPos[0];
  my $yPos = $self->{_pos}[1] - $playerPos[1];
  my $surface = ($self->{_dir}[1] == 1 ? $self->{_sprites}[0] :
                ($self->{_dir}[1] == -1 ? $self->{_sprites}[3] :
                ($self->{_dir}[0] == 1 ? $self->{_sprites}[2] :
                ($self->{_dir}[0] == -1 ? $self->{_sprites}[1] : $self->{_sprites}[0])))); 
  $self->{_surface}->surface($surface);
  $self->{_surface}->x ((($resolution{'width'}/2)-(14))+(($xPos * 14) -($yPos * 14)) - $self->{_offset});
  $self->{_surface}->y (((($xPos + $yPos) * 7) - 14) + $resolution{'height'} / 2);
  $self->{_surface}->draw($app);
}
return 1;
