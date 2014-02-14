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
use Entity::Enemy qw(createEnemy);
use Entity::data ':all';

#die() command override so we get a more informitive error (thanks to perl SDL's shite error reporting)
$SIG{ __DIE__ } = sub { print "SDL error: " . SDL::get_error . "\n"; Carp::confess( @_ ) };

#--Define Screen width/height
use constant SCREEN_W => 800;
use constant SCREEN_H => 600;

#--Define variables--
my $new_event = SDL::Event->new();

#--Load all static images (walls etc)--
my $wall = SDLx::Sprite->new( image => "img/room/wall_half.png" ) or die("Could not load wall image!");
my $tile = SDLx::Sprite->new( image => "img/room/grey.png" ) or die("Could not load tile image!");
my $stairs = SDLx::Sprite->new( image => "img/room/stairs.png" ) or die("Could not load stair image!");
my $water = SDLx::Sprite->new( image => "img/room/water.png" ) or die("Could not load water image!");
my $fall = SDLx::Sprite->new( image => "img/room/Lava_fall.png" ) or die("Could not load water image!");
my $house = SDLx::Sprite->new( image => "img/room/house.png" ) or die("Could not load water image!");
my $home = SDLx::Sprite->new( image => "img/room/house_side.png" ) or die("Could not load water image!");

my ($upStairsFound, $downStairsFound); #Variables for the "staircheck" system
#set both of these to 1 to prevent an infinite loading loop
$upStairsFound = 1;
$downStairsFound = 1;

my $level; #holds the current levelnumber
$level = 0; #make sure it's 0 to start with
my $maxLevel = 1; #which level is the last level

my @ents; #holds all the data hashrefs

my $app = SDLx::App->new(   #Create Window
  w => SCREEN_W,
  h => SCREEN_H,
  d =>24,
  event => $new_event,
  title => "Hack Plus ++",
  exit_on_quit => 1,
);

@room = (); #holds the room data 
my $offset; #holds the drawing offset data

#--actually start the program--
loadWorld(); #load the world!
initHandlers(); #initialise the handlers

$app->run(); #TIME TO RUN, COWARDS!

##WARNING: SUBRROUTINES AFTER THIS POINT##

sub handleEvents { #Handles the quit event
  my ($event, $app) = @_;
  if($event->type == SDL_QUIT) {
    $app->stop();
  }
}

sub initWorld { #Initialise the world
  my $offset = $_[0]; #get the offset
  for my $x (0 .. $#room) { #go through each row
    for my $y (0 .. $#{$room[$x]}) { #go through each colum
      my $char = $room[$x][$y];  #get the character
      if ($char eq 'p') { #init the player if P
        Entity::Player::initPlayer(["img/player/fighter/down.png","img/player/fighter/left.png","img/player/fighter/right.png","img/player/fighter/behind.png"], [$x, $y], $offset);
      }
      if ($char eq 'E') { #init an enemy with the grim reaper skin if E
        push(@ents, createEnemy(["img/enemies/grim_reaper/down.png","img/enemies/grim_reaper/left.png","img/enemies/grim_reaper/right.png","img/enemies/grim_reaper/behind.png"], [$x, $y], $offset, $app));
      }
      if ($char eq 'G') { #init an enemy with the gnome skin if G
        push(@ents, createEnemy(["img/enemies/gnome/down.png","img/enemies/gnome/left.png","img/enemies/gnome/right.png","img/enemies/gnome/behind.png"], [$x, $y], $offset, $app));
      }
    }
  }
}

sub drawWorld {
  my ($delta, $app) = @_;
  $upStairsFound = 0; #reset the stairs
  $downStairsFound = 0;
  for my $x (0 .. $#room) { #Go through each row
    for my $y (0 .. $#{$room[$x]}) { #Go through each colunm
      my $char = $room[$x][$y]; #get the character
      #--determine where our stuff has to blit to--
      my $dstx = ((800/2) - (14)) + (($x*14) - ($y*14)) -$offset; #long formula ;_;
      my $dsty = ($x+$y)*7;

      #--Image and sprite handling--
      if ($char eq '.' ||
          $char eq 'p' ||
          $char eq 'E' ||
          $char eq 'G' ) { #Floor drawing, handles the enemies and makes sure the floor is under them
        $tile->x($dstx);
        $tile->y($dsty);
        $tile->draw($app);
      }
      elsif ($char eq '#') { #wall drawing
        $wall->x($dstx);
        $wall->y($dsty - 14);
        $wall->draw($app);
      }
      elsif ($char eq 'w') { #water
        $water->x($dstx);
        $water->y($dsty - 14);
        $water->draw($app);
      }
      elsif ($char eq 'f') { #Waterfall, not implementing
        $fall->x($dstx);
        $fall->y($dsty - 14);
        $fall->draw($app);
      }
      elsif ($char eq 'h') { #house facing south
        $house->x($dstx);
        $house->y($dsty - 14);
        $house->draw($app);
      }
      elsif ($char eq 'a') { #house facing east
        $home->x($dstx);
        $home->y($dsty - 14);
        $home->draw($app);
      }
      if ($char eq 'd') { #Down stairs
        $stairs->x($dstx);
        $stairs->y($dsty);
        $stairs->draw($app);
        $downStairsFound = 1;
      }
      if ($char eq 'u') { #Up stairs
        $stairs->x($dstx);
        $stairs->y($dsty - 14);
        $stairs->draw($app);
        $upStairsFound = 1;
      }
    }
  }
}

sub checkWorld { #Check if the stairs have changed
  if (!$downStairsFound && $level != $maxLevel) { #if the stairs are gone and we're not at our max level
    $app->remove_all_handlers(); #delete the current handlers, they were for the last level
    $level++; #We're going further down so our level does the same
    @ents = (); #clear our entity data
    @room = ();
    print "Going down!\n";
    loadWorld(); #reload world
    initHandlers(); #reload event handlers
  }
  elsif (!$upStairsFound && $level != 0) { #if the stairs are gone and we're not on level 0
    $app->remove_all_handlers();
    $level--;
    @ents = ();
    @room = ();
    print "Going up!\n";
    loadWorld();
    initHandlers();
  }
}
  
sub loadWorld { #load a world into the $room
  $roomArea = '';
  open FILE, "worlds/$level.txt"; #open world
  while (<FILE>) { #slurp the file into the string
    $roomArea .= $_;
  }
  close FILE;
  print $roomArea . "\n";
  parseWorld(); #parse the world into the proper array
}

sub parseWorld {
  my $virtX = 0; #virtual X coordinate
  foreach my $line (split("\n", $roomArea)) { #split each line
    foreach my $char (split("", $line)) { #split line into characters
      push @{$room[$virtX]}, $char; #push the character into the world 2d array
      $virtX++; #increment virtual X
    }
    $virtX = 0; #Reset virtual X when we finish a line
  }
  #Compute best-fit##
  $offset = ((800/2) - 14) - ($#{$room[0]}*14);
}
 
sub initHandlers { #(re)initialise world events
  drawWorld(0, $app); #resets the stair variables
  $app->add_show_handler(sub {$app->draw_rect([0, 0, SCREEN_W, SCREEN_H], 0x000000)}); #clear the screen
  $app->add_show_handler(\&drawWorld); #draw the world
  $app->add_event_handler(\&checkWorld); #load our checkworld handler
  initWorld($offset); #initialise the world entities
  $app->add_event_handler(\&handleEvents); #add the event handler
  $app->add_event_handler(\&Entity::Player::doPlayerEvents); #add the player event handler
  $app->add_move_handler(\&Entity::Player::movePlayer); #add the player move handler
  $app->add_show_handler(\&Entity::Player::showPlayer); #etc.. etc..
  $app->add_show_handler(sub {$app->sync}); #draw everything to the screen
}
