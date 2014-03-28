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
use SDL::Mouse;
#--Define Entities--
use Entity::Player;
use Entity::data ':all';
use Time::HiRes qw(usleep time);
use Data::Dumper;
use Menu::Bar;


#die() command override so we get a more informitive error (thanks to perl SDL's shite error reporting)
$SIG{ __DIE__ } = sub { print "SDL error: " . SDL::get_error . "\n"; Carp::confess( @_ ) };

#--Define Screen width/height
our %resolution = (width => 800, height => 600);
our @playerPos = (0,0); #normally holds the player position, now instead holds camera position
#our @room = ([".","#"],["#","."]); #4x4 initial room
my  $tiles = "grassland";
#--Define variables--
my $drawSelect = 0;

#--Load all static images (walls etc)--
my ($wall, $tile, $stairs, $downStairs, $water, $house, $home, $hut, $blank, $coin);
my %EnemySprites = (G => SDLx::Sprite->new(image => "img/enemies/gnome/right.png"),
                    E => SDLx::Sprite->new(image => "img/enemies/grim_reaper/right.png"),
                    p => SDLx::Sprite->new(image => "img/player/caveman/down.png"),
                    P => SDLx::Sprite->new(image => "img/player/caveman/behind.png"),
                    O => SDLx::Sprite->new(image => "img/enemies/orc/right.png"),
                    I => SDLx::Sprite->new(image => "img/enemies/eye/right.png"));

my $selectTile = SDLx::Sprite->new(image => "img/selectTile.png");
my $selectWall = SDLx::Sprite->new(image => "img/selectWall.png");

#SDL::init(SDL_INIT_TIMER);
my $app = SDLx::App->new(   #Create Window
  w => $resolution{'width'},
  h => $resolution{'height'},
  d =>32,
  title => "Hack Plus - Level Editor",
  exit_on_quit => 1,
  resizeable => 1
);

my $offset = 0; #holds the drawing offset data
my $music;
my $curTile = '.';
my $maxX = 0;
my $maxY = 0;
my $fullscreen = 0;
my $menu = {
  File => {
    Save => sub { saveWorld() },
    Exit => sub { exit }
  },
  "Tiles" => {
    Tile => sub { $curTile = '.' },
    Wall => sub { $curTile = '#' },
    Water => sub { $curTile = 'w' },
    "House (right)" => sub { $curTile = 'a' },
    "House (down)" => sub { $curTile = 'h' },
    "House (back)" => sub { $curTile = 'b' },
    "Up stairs" => sub { $curTile = 'u' },
    "Down stairs" => sub { $curTile = 'd' },
    "Coin" => sub { $curTile = 'C' },
  },
  "Enemies" => {
    "Player (up spawn)" => sub { $curTile = 'P' },
    "Player (down/default spawn)" => sub { $curTile = 'p' },
    "Gnome" => sub { $curTile = 'G' },
    "Grim" => sub { $curTile = 'E' },
    "Orc" => sub { $curTile = 'O' },
    "Eye" => sub { $curTile = 'I' },
  },
  "Music" => {
    "Level_0" => sub { $music = "Level_0" },
    "Level_1" => sub { $music = "Level_1" },
    "Level_2" => sub { $music = "Level_2" },
    "Level_3" => sub { $music = "Level_3" },
    "Level_4" => sub { $music = "Level_4" },
    "Level_5" => sub { $music = "Level_5" },
    "TitleTheme" => sub { $music = "TitleTheme" }
  },
  "Tileset" => {
    "cave" => sub { $tiles = "cave"; loadTileSet($tiles) },
    "forest" => sub { $tiles = "forest"; loadTileSet($tiles) },
    "dark_forest" => sub { $tiles = "dark_forest"; loadTileSet($tiles) },
    "desert" => sub { $tiles = "desert"; loadTileSet($tiles) },
    "fortress" => sub { $tiles = "fortress"; loadTileSet($tiles) },
    "grassland" => sub { $tiles = "grassland"; loadTileSet($tiles) }
  },
  "Fullscreen" => {
    "800x600" => sub{ resizeAndFullscreen(800, 600) },
    "1280x720" => sub{ resizeAndFullscreen(1280, 720) },
    "1024x768" => sub{ resizeAndFullscreen(1024, 768) },
    "1366x768" => sub{ resizeAndFullscreen(1366, 768) },
    "1440x900" => sub{ resizeAndFullscreen(1440, 900) },
    "1680x1050" => sub{ resizeAndFullscreen(1680, 1050) },
    "1920x1080" => sub{ resizeAndFullscreen(1920, 1080) }
  }
};
my $order = [
  'File',
    ['Save', 'Exit'],
  'Tiles', 
    ['Tile', 'Wall', 'Water', 'House (right)', 'House (down)', 'House (back)', 'Up stairs', 'Down stairs', 'Coin'],
  'Enemies',
    ['Player (up spawn)', 'Player (down/default spawn)', 'Gnome', 'Grim', 'Orc', 'Eye'],
  'Music',
    ["Level_0", "Level_1", "Level_2", "Level_3", "Level_4", "Level_5", "TitleTheme"],
  'Tileset',
    ['cave', 'forest', 'dark_forest', 'desert', 'fortress', 'grassland'],
  'Fullscreen',
    ['800x600', '1280x720', '1024x768', '1366x768', '1440x900', '1680x1050', '1920x1080']
];

my $menuBar;

#--actually start the program--
#
loadWorld();
initHandlers(); #initialise the handlers
$app->run(); #TIME TO RUN, COWARDS!

##WARNING: SUBRROUTINES AFTER THIS POINT##

sub resizeAndFullscreen {
  if ($fullscreen) {
    $resolution{'height'} = 600;
    $resolution{'width'} = 800;
    $app->fullscreen();
    $app->resize($resolution{'width'}, $resolution{'height'});
    $fullscreen = 0;
  }
  else {
    my ($x, $y) = @_;
    $resolution{'height'} = $y;
    $resolution{'width'} = $x;
    $app->resize($resolution{'width'}, $resolution{'height'});   
    $app->fullscreen();
    $fullscreen = 1;
  }
}

sub handleEvents { #Handles the quit event
  my ($event, $app) = @_;
  if($event->type == SDL_QUIT) {
    $app->stop();
  }
  elsif($event->type == SDL_KEYDOWN) {
    my $key = $event->key_sym;
    if ($key == SDLK_a) {
      $playerPos[0] -= 1 if $playerPos[0] != 0;
    }
    elsif ($key == SDLK_d) {
      $playerPos[0] += 1;
    }
    elsif ($key == SDLK_w) {
      $playerPos[1] -= 1 if $playerPos[1] != 0;
    }
    elsif ($key == SDLK_s) {
      $playerPos[1] += 1;
    }
    elsif ($key == SDLK_SPACE) {
      if ($playerPos[0] > $maxX || $playerPos[1] > $maxY) {
        resizeWorld($playerPos[0], $playerPos[1]);
      }
      $room[$playerPos[0]][$playerPos[1]] = $curTile;
    }
    elsif ($key == SDLK_RSUPER) {
      exit;
    }
  }
}

sub drawWorld {
  my ($delta, $app) = @_;
  for my $x (0 .. $maxX) { #Go through each row
    for my $y (0 .. $maxY) { #Go through each colunm
      my $selectDraw;
      my $char = $room[$x][$y]; #get the character
      print "[$x][$y] : [$playerPos[0]][$playerPos[1]]\n" if !defined $char;
      next if !defined $char;
      #--determine where our stuff has to blit to--
      my $dstx = ($resolution{'width'}/2 - 14) + ($x - $playerPos[0] - $y + $playerPos[1])*14; #long formula ;_;
      my $dsty = ($x - $playerPos[0] + $y - $playerPos[1])*7 + $resolution{"height"} / 2;
      if ($x == $playerPos[0] && $y == $playerPos[1]) {
        $selectDraw = 1
      }
      else {
        $selectDraw = 0
      }
      drawTile($char, $selectDraw, $dstx, $dsty, $app);
    }
  }
}

sub drawTile {
  my @enemies = keys %EnemySprites;
  my($char, $selectDraw, $dstx, $dsty, $app) = @_;
  #--Image and sprite handling--
  foreach my $key (@enemies) {
    if ($char eq $key) {
      $tile->x($dstx);
      $tile->y($dsty);
      $tile->draw($app);
      my $ent = $EnemySprites{$key};
      $ent->x($dstx);
      $ent->y($dsty - 15);
      $ent->draw($app);
      $drawSelect = 2 if $selectDraw;
    }
  }
  if ($char eq '.') { #Floor drawing, handles the enemies and makes sure the floor is under them
    $tile->x($dstx);
    $tile->y($dsty);
    $tile->draw($app);
  }
  elsif ($char eq '#') { #wall drawing
    $wall->x($dstx);
    $wall->y($dsty - 15);
    $wall->draw($app);
    $drawSelect = 2 if $selectDraw;
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
    $drawSelect = 2 if $selectDraw;
  }
  elsif ($char eq 'a') { #house facing east
    $home->x($dstx);
    $home->y($dsty - 15);
    $home->draw($app);
    $drawSelect = 2 if $selectDraw;
  }
  elsif ($char eq 'b') { #back of the house
    $hut->x($dstx);
    $hut->y($dsty - 15);
    $hut->draw($app);
    $drawSelect = 2 if $selectDraw;
  }
  elsif ($char eq ' ') {
    $blank->x($dstx);
    $blank->y($dsty);
    $blank->draw($app);
  }
  elsif ($char eq 'u') { #Up stairs
    $stairs->x($dstx);
    $stairs->y($dsty - 15);
    $stairs->draw($app);
    $drawSelect = 2 if $selectDraw;
  }
  elsif ($char eq 'd') {
    $downStairs->x($dstx);
    $downStairs->y($dsty - 15);
    $downStairs->draw($app);
    $drawSelect = 2 if $selectDraw;
  }
  elsif ($char eq 'C') {
    $tile->x($dstx);
    $tile->y($dsty);
    $tile->draw($app);
    $coin->x($dstx);
    $coin->y($dsty);
    $coin->draw($app);
  }
}

sub setTile {
  $room[$playerPos[0]][$playerPos[1]] = $curTile;
}

sub drawSelector {
  my ($delta, $app) = @_;
  my $dstx = ($resolution{'width'}/2) - 14;
  my $dsty = -14 + $resolution{'height'} / 2;
  $selectTile->x($dstx);
  $selectTile->y($dsty + 14);
  $selectWall->x($dstx);
  $selectWall->y($dsty - 1);
  $selectTile->draw($app) if !$drawSelect;
  $selectWall->draw($app) if $drawSelect == 2;
  $drawSelect = 0;
}

sub saveWorld {
  for my $iter (0 .. 1) {
    $roomArea = '';
    for my $x (0 .. $#room) {
      for my $y (0 ..$#{$room[$x]}) {
        $roomArea .= $room[$x][$y];
      }
      $roomArea .= "\n";
    }
    @room = strToArray($roomArea);
  }
  $roomArea .= "tile_set: $tiles\n";
  $roomArea .= "music: $music\n";
  open(LEVEL, ">", "level.txt");
  print LEVEL $roomArea;
  close(LEVEL);
}

sub loadWorld { #load a world into the $room
  $roomArea = '';
  open FILE, "level.txt"; #open world
  while (<FILE>) { #slurp the file into the string
    $roomArea .= $_;
  }
  close FILE;
  print $roomArea . "\n";
  parseWorld(); #parse the world into the proper array
}

sub resizeWorld {
  my ($x, $y) = @_;
  $x = $maxX if $x < $maxX;
  $y = $maxY if $y < $maxY;
  my $string = makeWorldString($x, $y);
  my @world = strToArray($string);
  joinWorlds(\@world, \@room, $maxX, $maxY);
  @room = @world;
  $maxX = $x;
  $maxY = $y;
}

sub makeWorldString {
  my $string;
  my $x = shift;
  my $y = shift;
  $x += 1;
  $y += 1;
  for my $iter (0 .. $y) {
    $string .= "." x $x;
    $string .= "\n" if $iter != $y;
  }
  return $string;
}

sub joinWorlds {
  my ($world1, $world2, $xw, $yw) = @_;
  foreach my $x (0 .. $xw) {
    foreach my $y (0 .. $yw) {
      $$world1[$x][$y] = $$world2[$x][$y] if defined $$world2[$x][$y];
    }
  }
  return $world1;
}

sub strToArray {
  my @array = ();
  my $string = shift;
  my $virtX = 0;
  foreach my $line (split "\n", $string) {
    foreach my $char (split "", $line) {
      push @{$array[$virtX]}, $char;
      $virtX++;
    }
    $virtX = 0;
  }
  return @array;
}

sub parseWorld {
  my $virtX = 0; #virtual X coordinate
  my $virtY = 0;
  foreach my $line (split("\n", $roomArea)) { #split each line
    my @worldOpts = split(": ", $line); #Check for world options
    if ($worldOpts[0] eq "tile_set") { #tileset handling (e.g. tile_set: cave)
      loadTileSet($worldOpts[1]); #load the tileset into memory
      $tiles = $worldOpts[1];
    }
    elsif ($worldOpts[0] eq "music") { #music handling (e.g. music: Level_0)
      $music = $worldOpts[1];
    }
    else {
      foreach my $char (split("", $line)) { #split line into characters
        push @{$room[$virtX]}, $char; #push the character into the world 2d array
        $virtX++; #increment virtual X
      }
      $maxX = ($virtX - 1) if $virtX > $maxX;
      $virtX = 0; #Reset virtual X when we finish a line
      $virtY++;
    }
  }
  $maxY = $virtY - 1;
  #Compute best-fit##
  $offset = 0 #(($resolution{'width'}/2) - 14) - ($#{$room[0]}*14);
}

sub initHandlers { #(re)initialise world events
  my $deInitEnemies = shift;
  #drawWorld(0, $app); #resets the stair variables
  $app->add_show_handler(sub { my($delta, $app) = @_; $app->draw_rect([0, 0, $resolution{'width'}, $resolution{'height'}], [50, 10, 50])}); #clear the screen
  $app->add_event_handler(\&handleEvents); #add the event handler
  $app->add_show_handler(\&drawWorld); #draw the world
  $app->add_show_handler(\&drawSelector); 
  $menuBar = Menu::Bar::init($menu, $order, $app);
  $app->add_show_handler(\&drawCurrentTile);
  $app->add_show_handler(\&drawSelectedTile);
  $app->add_show_handler(sub {$app->sync}); #draw everything to the screen
}

sub drawCurrentTile {
  my($delta, $app) = @_;
  my $surface = SDLx::Surface->new(w => 36, h => 36);
  $surface->draw_rect([0, 0, 35, 35], [100,60,100]);
  $surface->draw_rect([0, 1, 34, 34], [50,10,50]);
  drawTile($curTile, 0, 2, 35 -17, $surface);
  $surface = SDL::GFX::Rotozoom::surface($surface->surface(), 0, 2, SMOOTHING_OFF);
  $app->blit_by($surface, [0,0,72,72], [0, $resolution{'height'} - 70, 72, 72]);
}

sub drawSelectedTile {
  my($delta, $app) = @_;
  my $surface = SDLx::Surface->new(w => 36, h => 36);
  $surface->draw_rect([0, 0, 36, 35], [100,60,100]);
  $surface->draw_rect([1, 1, 35, 36], [50,10,50]);
  my $char;
  if (defined $room[$playerPos[0]][$playerPos[1]]) {
    $char = $room[$playerPos[0]][$playerPos[1]];
  }
  else {
    $char = " ";
  }
  drawTile($char, 0, 3, 35 -17, $surface);
  $surface = SDL::GFX::Rotozoom::surface($surface->surface(), 0, 2, SMOOTHING_OFF);
  $app->blit_by($surface, [0,0,72,72], [$resolution{'width'} - 70, $resolution{'height'} - 70, 72, 72]);
}
# death screen, grim reaper kills main player

sub loadTileSet {
  my $tileset = shift;
  $wall = SDLx::Sprite->new( image => "img/room/$tileset/wall.png" ) or die("Could not load wall image for tileset $tileset!");
  $tile = SDLx::Sprite->new( image => "img/room/$tileset/tile.png" ) or die("Could not load tile image for tileset $tileset!");
  $stairs = SDLx::Sprite->new( image => "img/room/$tileset/stairs.png" ) or die("Could not load stair image for tileset $tileset!");
  $downStairs = SDLx::Sprite->new( image => "img/room/$tileset/downStairs.png" ) or die ("Could not load downstairs image for tileset $tileset!");
  $water = SDLx::Sprite->new( image => "img/room/$tileset/water.png" ) or die("Could not load water image for tileset $tileset!");
  $house = SDLx::Sprite->new( image => "img/room/$tileset/house.png" ) or die("Could not load house image for tileset $tileset!");
  $home = SDLx::Sprite->new( image => "img/room/$tileset/house_side.png" ) or die("Could not load house side image for tileset $tileset!");
  $coin = SDLx::Sprite->new( image => "img/room/coin.png" ) or die("Could not load coin image for room!");
  $blank = SDLx::Sprite->new( image => "img/room/$tileset/blank.png") or die("Could not load blank image for tileset $tileset!");
  $hut = SDLx::Sprite->new( image => "img/room/$tileset/house_back.png") or die("Could not load house back image for tileset $tileset!");
}

