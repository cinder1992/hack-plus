#!/usr/bin/perl
use Carp;
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
use SDL::Events;
#--Define Entities--
use Entity::Player;
#use Entity::Logical::World;
#use Entity::Static::Floor;
#use Entity::Static::Wall;
$SIG{ __DIE__ } = sub { print "SDL error: " . SDL::get_error . "\n"; Carp::confess( @_ ) };
#--Define Screen width/height
use constant SCREEN_W => 800;
use constant SCREEN_H => 600;
#--Define variables--
my ($roomArea, @room);

my $new_event = SDL::Event->new();

my $world = SDLx::Surface->load( 'img/room/world.bmp', 'bmp') or die "Could not load image";
my $wall = SDLx::Sprite->new( image => "img/room/wall_half.png" ) or die("Could not load wall image!"); #Load the wall image
my $tile = SDLx::Sprite->new( image => "img/room/tile.png" ) or die("Could not load tile image!");
my %ents;
#--Define Entities--
#$ents{hex '0xFFFFFF'} = \&drawFloor($tile);
#$ents{hex '0x666666'} = \&drawWall($wall);

my $app = SDLx::App->new(   #Create Window
  w => SCREEN_W,
  h => SCREEN_H,
  d =>24,
  event => $new_event,
  title => "I'm a particle!",
  exit_on_quit => 1,
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

my $virtX = 0;

foreach my $line (split("\n", $roomArea)) {
  foreach my $char (split("", $line)) {
    push @{$room[$virtX]}, $char;
    $virtX++;
  }
  $virtX = 0; #Reset virtual X
}
my $offset = ((800/2) - 14) - ($#{$room[0]}*14);
initWorld($offset);
#Compute best-fit##
$app->add_event_handler(\&handleEvents);
$app->add_event_handler(\&Entity::Player::doPlayerEvents);
$app->add_move_handler(\&Entity::Player::movePlayer);
$app->add_show_handler(sub {$app->draw_rect([0, 0, SCREEN_W, SCREEN_H], 0x000000)});
$app->add_show_handler(\&drawWorld);
$app->add_show_handler(\&Entity::Player::showPlayer);

$app->add_show_handler(sub {$app->sync});

$app->run();

sub handleEvents {
  my ($event, $app) = @_;
  if($event->type == SDL_QUIT) {
    $app->stop();
  }
}

sub drawFloor {
  my $img = shift;
  my $x = shift;
  my $y = shift;
  $img->x($x);
  $img->y($y);
  $img->draw($app);
}

sub drawWall {
  my $img = shift;
  my $x = shift;
  my $y = shift;
  $img->x($x);
  $img->y($y);
  $img->draw($app);
}

sub initWorld {
  my $offset = $_[0];
  for my $x (0 .. $#room) {
    for my $y (0 .. $#{$room[$x]}) {
      my $char = $room[$x][$y];  
      if ($char eq 'p') {
        Entity::Player::initPlayer(["img/player/tourist/down.png","img/player/tourist/left.png","img/player/tourist/right.png","img/player/tourist/behind.png"], [$x, $y], $offset);
      }
    }
  }
}

sub drawWorld {
  my ($delta, $app) = @_;
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
}

