#!/usr/bin/perl
use strict;
use warnings;
use SDL;
use SDL::Video;
use SDLx::App;
use SDLx::Surface;
use SDLx::Sprite;
use SDL::Image;
use SDL::GFX::Rotozoom;
use SDLx::Rect;
use SDL::Event;
use constant SCREEN_W => 800;
use constant SCREEN_H => 600;
my ($exiting, $srcRect, $dstRect, $sprite, $event, @mouse, $roomArea, @room);

my $app = SDLx::App->new(   #Create Window
  w => SCREEN_W,
  h => SCREEN_H,
  d =>24,
  title => "I'm a particle!",
  exit_on_quit => 1
);

$roomArea = <<EOR
..####..
.#....#.
#......#
#......#
#..p...#
#......#
.#....#.
..####..
EOR
;
@room = ();

my $wall = SDLx::Sprite->new( image => "img/room/wall.png" ) or die("Could not load wall image!"); #Load the wall image
my $tile = SDLx::Sprite->new( image => "img/room/tile.png" ) or die("Could not load tile image!");
#my $backdrop = SDLx::Surface->new( width => 800, height => 600, depth => 32);
#SDL::Video::set_alpha( $backdrop, 0, 100);
#$backdrop->draw_rect([0,0,800,600],[0,0,0,255]);  #
my $virtX = 0;

foreach my $line (split("\n", $roomArea)) {
  foreach my $char (split("", $line)) {
    push @{$room[$virtX]}, $char;
    $virtX++;
  }
  $virtX = 0; #Reset virtual X
}

##Compute best-fit##
my $offset = ((800/2) - 14) - ($#{$room[0]}*14);

for my $x (0 .. $#room) {
  for my $y (0 .. $#{$room[$x]}) {
    my $char = $room[$x][$y];
    my $dstx = ((800/2) - (14)) + (($x*14) - ($y*14)) - $offset; #compute virtual -> real coords
    my $dsty = ($x+$y)*7;    
    if ($char eq '.') {
      $tile->x($dstx);
      $tile->y($dsty);
      $tile->draw($app);
    }
    elsif ($char eq '#') {
      $wall->x($dstx);
      $wall->y($dsty - 14);
      $wall->draw($app);
    }
  }
}
$srcRect = SDLx::Rect->new(0,0,800,600);
$dstRect = SDLx::Rect->new(0,0,30,15);
$event = SDL::Event->new();    # create one global event

#my $zoomWin = SDL::GFX::Rotozoom::surface( $backdrop, 0, 1, SMOOTHING_OFF);
while(!$exiting) {
  $app->flip();
  handleEvents();
}

sub mouseEvent {
  my($mouse_mask, $mouse_x, $mouse_y) = @{SDL::Events::get_mouse_state()};
  @mouse = ($mouse_x, $mouse_y);
}

sub quitEvent {
  exit;
}
sub handleEvents {
  SDL::Events::pump_events();
  while(SDL::Events::poll_event($event)) {
    if($event->type == SDL_QUIT) {
      &quitEvent();
    }
    elsif($event->type == SDL_MOUSEBUTTONDOWN)
    {
      &mouseEvent($event);
    }
  }
}

