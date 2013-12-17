#!/usr/bin/perl
use strict;
use warnings;
use SDL;
use SDLx::App;
use SDLx::Surface;
use SDL::Image;
use SDL::GFX::Rotozoom;
use SDLx::Rect;
use SDL::Event;
use SDLx::Text;
use constant SCREEN_W => 800;
use constant SCREEN_H => 600;
my ($exiting, $srcRect, $dstRect, $sprite, $event, @mouse, $backdrop, $roomArea, @room);

my $app = SDLx::App->new(   #Create Window
  w => SCREEN_W,
  h => SCREEN_H,
  d => 32,
  title => "I'm a particle!",
  exit_on_quit => 1
);

$roomArea = <<EOR
........
...##...
..#..#..
.#....#.
.#....#.
..#..#..
...##...
........
EOR
;
@room = ();
my $wall = SDL::Image::load( 'img/room/wall.png' ) or die("Could not load wall image!"); #Load the wall image
my $tile = SDL::Image::load( 'img/room/tile.png' ) or die("Could not load tile image!");
$backdrop = SDLx::Surface->new( width => 800, height => 600 );
my $src = SDLx::Rect->new(0,0,800,600); #set up source and dest
my $dst = SDLx::Rect->new(0,0,800,600);
my $virtX = 0; #create our virtual coordinates
my $virtY = 0;

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
    $dst->x(((800/2) - (14)) + (($x*14) - ($y*14)) - $offset); #compute virtual -> real coords
    $dst->y(($x+$y)*7);    
    if ($char eq '.') {
      $app->blit_by($tile, $src, $dst);
    }
    elsif ($char eq '#') {
      $dst->y($dst->y - 14);
      $app->blit_by($wall, $src, $dst);
    }
  }
}
$app->update();

$srcRect = SDLx::Rect->new(0,0,800,600);
$dstRect = SDLx::Rect->new(0,0,400,800);
$event = SDL::Event->new();    # create one global event

while(!$exiting) {
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

