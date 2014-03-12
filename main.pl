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
use SDLx::Music;
use SDLx::Sound;
use SDL::Mixer::Music;
use SDLx::Text;
use Menu::Title;
#--Define Entities--
use Entity::Player;
use Entity::Enemy qw(createEnemy);
use Entity::data ':all';
use Time::HiRes qw(usleep time);
use Data::Dumper;

use threads;
use threads::shared;
use SDL::Time;


#die() command override so we get a more informitive error (thanks to perl SDL's shite error reporting)
$SIG{ __DIE__ } = sub { print "SDL error: " . SDL::get_error . "\n"; Carp::confess( @_ ) };

#--Define Screen width/height
our %resolution = (width => 800, height => 600);
our @playerPos = (0,0);

#--Define variables--
my $new_event = SDL::Event->new();

my $snd = SDLx::Sound->new();

our $tick;
my $timerTick :shared = 0;
my $timerID;

my $text_box;
my $score = 0;
my $numcoins;
my $newnumcoins;


###################### SDL Text Box ###########################
# Add in a text box/location; we'll put text in it later
$text_box = SDLx::Text->new(size=>'24', # font can also be specified
                            color=>[255,255,255], # [R,G,B]
                            x=> 20,
                            y=> 20);
###############################################################


#--Load all static images (walls etc)--
my ($wall, $tile, $stairs, $water, $house, $home, $coin);

my @death = (SDLx::Sprite->new( image => "img/death1.png" ), # loads death screen
             SDLx::Sprite->new( image => "img/death2.png" ), # loads death screen
             SDLx::Sprite->new( image => "img/death3.png" ), # loads death screen
             SDLx::Sprite->new( image => "img/death4.png" ), # loads death screen
             SDLx::Sprite->new( image => "img/death5.png" ), # loads death screen
             SDLx::Sprite->new( image => "img/death6.png" ), # loads death screen
             SDLx::Sprite->new( image => "img/death7.png" ), # loads death screen
             SDLx::Sprite->new( image => "img/death8.png" ),
             SDLx::Sprite->new( image => "img/death.png" )   # loads death screen
);# loads death screen

my ($upStairsFound, $downStairsFound, $levelDir); #Variables for the "staircheck" system
#set both of these to 1 to prevent an infinite loading loop
$upStairsFound = 1;
$downStairsFound = 1;
$levelDir = 1;

my $level; #holds the current levelnumber
$level = 0; #make sure it's 0 to start with
my $maxLevel = 3; #which level is the last level

my @ents; #holds all the data hashrefs

our $hackPlusMusic = SDLx::Music->new();
$hackPlusMusic->data(
  TitleTheme => 'music/Tempting Secrets.ogg',
  Level_0 => 'music/Minstrel Guild.ogg'
);
my $musicData;
my $fadeTime = 0;
#SDL::init(SDL_INIT_TIMER);
my $app = SDLx::App->new(   #Create Window
  w => $resolution{'width'},
  h => $resolution{'height'},
  d =>32,
  event => $new_event,
  title => "Hack Plus ++",
  exit_on_quit => 1,
);

@room = (); #holds the room data 
my $offset; #holds the drawing offset data
my $titleMenu = {
  "New Game" => \&startGame,
  "Exit" => sub{ exit }
};
my $order = [
  "New Game",
  "Exit"
];

$hackPlusMusic->play($hackPlusMusic->data("TitleTheme"), loops => 1);
$app->add_show_handler(\&drawMenu);
my $menuTitle = Menu::Title::init($titleMenu, $order, $app);
$app->add_show_handler(sub{ $app->sync });
my $menu = SDLx::Sprite->new( image => "img/main-menu2.png" );
$app->run();

#--actually start the program--
sub startGame {
  $app->remove_all_handlers();
  $timerID = SDL::Time::add_timer(200, 'moveTimer');
  loadWorld(); #load the world!
  initHandlers(1); #initialise the handlers
}

##WARNING: SUBRROUTINES AFTER THIS POINT##

sub drawMenu {
  my ($delta, $app) = @_;
  $app->draw_rect([0, 0, $resolution{'width'}, $resolution{'height'}], 0x000000);
  my $surface = SDL::GFX::Rotozoom::surface ($menu->surface(), 0, 1.8, SMOOTHING_OFF);
  my $sprite = SDLx::Sprite->new( surface => $surface);
  $sprite->x(($resolution{'width'} / 2) - $sprite->w() / 2);
  $sprite->y(($resolution{'height'} / 2) - $sprite->h() / 2);
  $sprite->draw($app);
}
  


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
      if ($char eq 'p' or $char eq 'P') { #init the player if P
        Entity::Player::initPlayer(["img/player/fighter/down.png","img/player/fighter/left.png","img/player/fighter/right.png","img/player/fighter/behind.png"], [$x, $y], $offset);
      }
      if ($char eq 'E') { #init an enemy with the grim reaper skin if E
        push(@ents, createEnemy(["img/enemies/grim_reaper/down.png","img/enemies/grim_reaper/left.png","img/enemies/grim_reaper/right.png","img/enemies/grim_reaper/behind.png"], [$x, $y], $offset, 1, $app));
      }
      if ($char eq 'G') { #init an enemy with the gnome skin if G
        push(@ents, createEnemy(["img/enemies/gnome/down.png","img/enemies/gnome/left.png","img/enemies/gnome/right.png","img/enemies/gnome/behind.png"], [$x, $y], $offset, 0, $app));
      }
      if ($char eq 'C') {
     }
    }
  }
}

sub drawWorld {
  my ($delta, $app) = @_;
  $upStairsFound = 0; #reset the stairs
  $downStairsFound = 0;
  $newnumcoins = 0;
  for my $x (0 .. $#room) { #Go through each row
    for my $y (0 .. $#{$room[$x]}) { #Go through each colunm
      my $char = $room[$x][$y]; #get the character
      #--determine where our stuff has to blit to--
      my $dstx = (($resolution{'width'}/2) - (14)) + ((($x - $playerPos[0])*14) - (($y - $playerPos[1])*14)) -$offset; #long formula ;_;
      my $dsty = (($x - $playerPos[0])+($y - $playerPos[1]))*7 + $resolution{"height"} / 2;

      #--Image and sprite handling--
      if ($char eq '.' ||
          $char eq 'p') { #Floor drawing, handles the enemies and makes sure the floor is under them
        $tile->x($dstx);
        $tile->y($dsty);
        $tile->draw($app);
      }
      if ($char eq 'p' || $char eq 'P') {
        @playerPos = ($x, $y);
        &Entity::Player::showPlayer(0, $app);
      }
      if ($char eq 'E' || $char eq 'G') {
        $tile->x($dstx);
        $tile->y($dsty);
        $tile->draw($app);
        foreach my $entity (@ents) {
          my $entPosX = $entity->{_pos}[0];
          my $entPosY = $entity->{_pos}[1];
          if($entPosX == $x && $entPosY == $y) {
            &Entity::Enemy::showEnemy($entity, 0, $app);
          }
        }
      }
      elsif ($char eq '#') { #wall drawing
        $wall->x($dstx);
        $wall->y($dsty - 15);
        $wall->draw($app);
      }
      elsif ($char eq 'w') { #water
        $water->x($dstx);
        $water->y($dsty - 15);
        $water->draw($app);
      }
      elsif ($char eq 'h') { #house facing south
        $house->x($dstx);
        $house->y($dsty - 15);
        $house->draw($app);
      }
      elsif ($char eq 'a') { #house facing east
        $home->x($dstx);
        $home->y($dsty - 15);
        $home->draw($app);
      }
      elsif ($char eq 'C') {
        $tile->x($dstx);
        $tile->y($dsty);
        $tile->draw($app);
        $coin->x($dstx);
        $coin->y($dsty);
        $coin->draw($app);
        $newnumcoins++;
      }
      if ($char eq 'u' || $char eq 'd') { #Up stairs
        $stairs->x($dstx);
        $stairs->y($dsty - 15);
        $stairs->draw($app);
        $upStairsFound = 1 if $char eq 'u';
        $downStairsFound = 1 if $char eq 'd';
      }
    }
  }
  $score+= 1*($numcoins-$newnumcoins);
  $numcoins=$newnumcoins;
}

sub fadeOut {
  my ($time, $s, $app) = @_;
  my $blitSurf = SDLx::Surface->new(w => $resolution{'width'}, h => $resolution{'height'}, d => 32);
  if ($fadeTime == 0) {
    $fadeTime = Time::HiRes::time;
  }
  my $curTime = Time::HiRes::time;
  my $totalTime = $curTime - $fadeTime;
  if ($totalTime >= $time) {
    $fadeTime = 0;
    $app->draw_rect([0,0, $resolution{'width'}, $resolution{'height'}], 0x000000FF);
    $app->sync();
    $app->remove_all_handlers();
    @ents = ();
    @room = ();
    loadWorld();
    initHandlers(1);
  }
  else {
    my $coloTime = $totalTime / $time;
    my $alpha = 255 * $coloTime;
    my $surface = $app->surface;
    $surface = SDL::Video::set_alpha($surface, SDL_SRCALPHA, $alpha);
    $app->surface($surface);
    $blitSurf->draw_rect([0,0, $resolution{'width'}, $resolution{'height'}], [0,0,0,$alpha]);
    $blitSurf->blit($app);
  }
}

sub checkWorld { #Check if the stairs have changed
  if (!$downStairsFound && $level != $maxLevel) { #if the stairs are gone and we're not at our max level
    $app->remove_all_handlers(); #delete the current handlers, they were for the last level
    $level++; #We're going further down so our level does the same
    $levelDir = 1;
    print "Going down!\n";
    initHandlers(0); #reload event handlers
  }
  elsif (!$upStairsFound && $level != 0) { #if the stairs are gone and we're not on level 0
    $app->remove_all_handlers();
    $level--;
    $levelDir = -1;
    print "Going up!\n";
    initHandlers(0);
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
  $hackPlusMusic->play($musicData, loops => 1);
}

sub parseWorld {
  my $virtX = 0; #virtual X coordinate
  $numcoins = 0;
  foreach my $line (split("\n", $roomArea)) { #split each line
    my @worldOpts = split(": ", $line); #Check for world options
    if ($worldOpts[0] eq "tile_set") { #tileset handling (e.g. tile_set: cave)
      print "loading tileset: $worldOpts[1]";
      loadTileSet($worldOpts[1]); #load the tileset into memory
    }
    elsif ($worldOpts[0] eq "music") { #music handling (e.g. music: Level_0)
      $musicData = $hackPlusMusic->data($worldOpts[1]);
    }
    else {
      foreach my $char (split("", $line)) { #split line into characters
        if ($char eq 'p' and $levelDir != 1) { #check where we need to put the player depending on the world format.
          $char = '.';
        }
        elsif($char eq 'P' and $levelDir != -1) {
          $char = '.';
        }
        elsif($char eq 'C') {
          $numcoins++;
        }
        push @{$room[$virtX]}, $char; #push the character into the world 2d array
        $virtX++; #increment virtual X
      }
      $virtX = 0; #Reset virtual X when we finish a line
    }
  }
  #Compute best-fit##
  $offset = 0 #(($resolution{'width'}/2) - 14) - ($#{$room[0]}*14);
}

sub initHandlers { #(re)initialise world events
  my $deInitEnemies = shift;
  SDL::Time::remove_timer($timerID); 
  $timerID = SDL::Time::add_timer(200, 'moveTimer');
  $app->add_move_handler(sub {if ($timerTick and !$tick) {$timerTick = 0; $tick = 1} else {$tick = 0}});
  $app->add_show_handler(sub {$app->draw_rect([0, 0, $resolution{'width'}, $resolution{'height'}], 0x000000)}); #clear the screen
  $app->add_event_handler(\&checkWorld) if $deInitEnemies; #load our checkworld handler
  initWorld($offset) if $deInitEnemies; #initialise the world entities
  $app->add_event_handler(\&handleEvents); #add the event handler
  $app->add_event_handler(\&Entity::Player::doPlayerEvents) if $deInitEnemies; #add the player event handler
  $app->add_move_handler(\&Entity::Player::movePlayer) if $deInitEnemies; #add the player move handler
  #$app->add_show_handler(\&Entity::Player::showPlayer); #etc.. etc..
  $app->add_show_handler(\&drawWorld); #draw the world
  $app->add_show_handler(sub {&fadeOut(1, @_)}) if !$deInitEnemies;
  SDL::Mixer::Music::fade_out_music(1000) if !$deInitEnemies;
  $app->add_show_handler(\&zoomApp); #Zoom the entire app's screen
  $app->add_show_handler(\&writeScore);
  $app->add_show_handler(sub {$app->sync}); #draw everything to the screen
  drawWorld(0, $app); #resets the stair variables
}

# death screen, grim reaper kills main player

sub death {
  SDL::Mixer::Music::fade_out_music(2000); #Manual fadeout calling b/c documentation was for a stub function
  $snd->play("music/evilLaugh.ogg");    
  foreach my $sprite (@death) {
    $app->draw_rect([0, 0, $resolution{'width'}, $resolution{'height'}], 0x000000);
    $sprite->x(($resolution{'width'} / 2) - $sprite->w() / 2);
    $sprite->y(($resolution{'height'} / 2) - $sprite->h() / 2);
    $sprite->draw($app);
    $app->sync;

    usleep 500000;
  }
  sleep 1;
  exit;
}

sub loadTileSet {
  my $tileset = shift;
  $wall = SDLx::Sprite->new( image => "img/room/$tileset/wall.png" ) or die("Could not load wall image for tileset $tileset!");
  $tile = SDLx::Sprite->new( image => "img/room/$tileset/tile.png" ) or die("Could not load tile image for tileset $tileset!");
  $stairs = SDLx::Sprite->new( image => "img/room/$tileset/stairs.png" ) or die("Could not load stair image for tileset $tileset!");
  $water = SDLx::Sprite->new( image => "img/room/$tileset/water.png" ) or die("Could not load water image for tileset $tileset!");
  $house = SDLx::Sprite->new( image => "img/room/$tileset/house.png" ) or die("Could not load house image for tileset $tileset!");
  $home = SDLx::Sprite->new( image => "img/room/$tileset/house_side.png" ) or die("Could not load house side image for tileset $tileset!");
  $coin = SDLx::Sprite->new( image => "img/room/coin.png" ) or
  die("Could not load coin image for room!");
}

sub zoomApp {
  my ($delta, $app) = @_;
  my $surface = SDL::GFX::Rotozoom::surface($app->surface, 0, 2, SMOOTHING_OFF);
  $app->draw_rect([0,0,$resolution{'width'}, $resolution{'height'}], 0x000000);
  $app->blit_by($surface, [$resolution{'width'} / 2, $resolution{'height'} / 2, $resolution{'width'}, $resolution{'height'},], [0, 0, $resolution{'width'}, $resolution{'height'}]);
}

sub moveTimer {$timerTick = 1; return 150}

sub writeScore {
  $text_box->write_to($app,"Coins: ($score)");
}
