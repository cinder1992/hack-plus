#!/usr/bin/perl
use strict;
use warnings;
use SDL;
use SDLx::App;
use SDL::Surface;
use SDL::Mouse;
use SDL::Video;
use SDLx::Rect;
use SDL::Event;
use SDL::Events;
use OpenGL qw(:all);
use constant SCREEN_W => 800;
use constant SCREEN_H => 600;
my ($exiting, $event, @mouse, $roomArea, @room, %camera, $deltaPitch, $deltaYaw);

my $app = SDLx::App->new(   #Create Window
  w => SCREEN_W,
  h => SCREEN_H,
  title => "I'm a particle!",
  exit_on_quit => 1,
  gl => 1
);

SDL::Mouse::show_cursor(SDL_DISABLE);
$app->grab_input(SDL_GRAB_ON);
#define openGL functions
my @whitespec = (1,1,1);
my @blackamb = (0,0,0);
my @whitedif = (1,1,1);
glEnable(GL_DEPTH_TEST);
glEnable(GL_LIGHTING);
glEnable(GL_LIGHT0);
glEnable(GL_NORMALIZE);
glEnable(GL_COLOR_MATERIAL);
glMatrixMode(GL_PROJECTION);
glLoadIdentity;
glLightfv_p(GL_LIGHT0, GL_SPECULAR, @whitespec, 0);
glLightfv_p(GL_LIGHT0, GL_AMBIENT, @blackamb, 0);
glLightfv_p(GL_LIGHT0, GL_DIFFUSE, @whitedif, 0);
gluPerspective(60, SCREEN_W / SCREEN_H, 1, 1000);
$camera{'x'} = 0; $camera{'y'} = 15; $camera{'z'} = -15;
glutInit();

$roomArea = <<EOR
  ....  
 ...... 
........
..l.....
........
........
 ...... 
  .... 
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

$deltaYaw = 0;
$deltaPitch = 0;
$event = SDL::Event->new();    # create one global event
gluLookAt($camera{'x'}, $camera{'y'}, $camera{'z'}, 0, 0, 0, 0, 1, 0);
while (!$exiting) {
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glRotatef($deltaYaw, 0, 1, 0);
  glRotatef($deltaPitch, 1, 0, 0);
  $deltaYaw = 0;
  $deltaPitch = 0;
  positionLight(drawWorld(@room));
  $app->sync();
  handleEvents();
}

sub quitEvent {
  exit;
}

sub handleEvents {
  SDL::Events::pump_events();
  my $key = ($event->type == 2 or $event->type == 3) ? $event->key_sym : "";
  while(SDL::Events::poll_event($event)) {
    if($event->type == SDL_QUIT) {
      &quitEvent();
    }
    elsif($event->type == 4) {
      $deltaYaw = -$event->motion_xrel;
      $deltaPitch = -$event->motion_yrel;
    }
    elsif($key eq ord('q')) {
      &quitEvent();
    }
  }
}

sub draw_cube {
  my $mul = shift;
  my $type = shift;
  # A simple cube
  my @indices = qw( 6 7 3  3 2 6
                    5 6 2  2 1 5
                    4 5 1  1 0 4
                    7 4 0  0 3 7
                    5 4 7  7 6 5
                    0 1 2  2 3 0);

  my @vertices = ([-0.5, -0.5, -0.5], [0.5, -0.5, -0.5], [0.5, -0.5, 0.5], [-0.5, -0.5, 0.5],
                  [-0.5,  0.5, -0.5], [0.5,  0.5, -0.5], [0.5,  0.5, 0.5], [-0.5,  0.5, 0.5]);

  glBegin($type);
  foreach my $triangle (0 .. 11) {
    foreach my $vertex (0 .. 2) {
      my $index  = $indices[3 * $triangle + $vertex];
      my $coords = $vertices[$index];
      glNormal3f($$coords[0] * $mul * 1.1, $$coords[1] * $mul * 1.1, $$coords[2] * $mul * 1.1);
      glVertex3f($$coords[0] * $mul, $$coords[1] * $mul, $$coords[2] * $mul);
    }
  }
  glEnd;
}

sub drawWorld {
  my @world = @_;
  glPushMatrix(); #Reset Matrix
  my $maxY = 0;
  glBegin(GL_TRIANGLES);
  my @offset = (0, 0,0);
  my @lightPos;
  for my $x (0 .. $#world) {
    glTranslatef(1,0,0); #translate according to our coordinate
    for my $y (0 .. $#{$world[$x]}) {
      my @grid;
      my $char = $world[$x][$y];
      my $i;
      for ($i = 0, $i <= 8, $i++) {
        if($i < 3) {
          if ($x > 0 && $y > 0) {push(@grid, $world[$x-1][$y-1+$i] eq '#' ? 2 : (($world[$x-1][$y-1+$i] eq " " or "") ? 0 : 1))}
          else {push(@grid,0);}
        }
        if($i > 3) {
          if ($x < 7 && $y < 7) { push(@grid, $world[$x+1][$y-1+($i-6)] eq '#' ? 2 : (($world[$x+1][$y-1+($i-6)] eq " " or "") ? 0 : 1))}
          else {push(@grid,0)}
        }
        else {
          if($y < 0 || $y > 7) { push(@grid, 0) }
          else { push(@grid, $world[$x][$y-1+($i-3)] eq '#' ? 2 : (($world[$x][$y-1+($i-6)] eq " " or "") ? 0 : 1 ))}
        }
      }

      my @localOffset = ($offset[0] + $x, $offset[1], $offset[2] + $y);
      if ($char eq '.') {
        glColor3d(0,0.5,0);
        drawFloor($localOffset[0], $localOffset[1], $localOffset[2], floorNormals(@grid));
      }
      elsif ($char eq '#') {;
        glColor3d(0,0.5,0);
        drawFloor($localOffset[0], $localOffset[1], $localOffset[2], floorNormals(@grid));
        glColor3d(0.2,0.2,0.2);
      }
      elsif ($char eq 'l') {
        @lightPos = ($x, 1.5, $y);
        glColor3d(0,0.5,0);
        drawFloor($localOffset[0], $localOffset[1], $localOffset[2], floorNormals(@grid));
      }
      $maxY=$y;
    }
    glTranslatef(0,0,-$maxY-1);
  } 
  glEnd();
  glPopMatrix();
  return @lightPos;
}

sub positionLight {
  my @light = @_;
  glLightfv_p(GL_LIGHT0, GL_POSITION, @light, 0);
  glLightfv_p(GL_LIGHT0, GL_POSITION, $light[0]+2,$light[1]+2,$light[2]+2, 1);
}

sub drawFloor {
  my $xOff = shift;
  my $yOff = shift;
  my $zOff = shift;
  my $normals = shift;
  # A cubic world node
  my @indices = qw( 6 7 3  3 2 6
                    5 6 2  2 1 5
                    4 5 1  1 0 4
                    7 4 0  0 3 7
                    5 4 7  7 6 5
                    0 1 2  2 3 0);

  my @vertices = ([-0.5, -0.5, -0.5], [0.5, -0.5, -0.5], [0.5, -0.5, 0.5], [-0.5, -0.5, 0.5],
                  [-0.5,  0.5, -0.5], [0.5,  0.5, -0.5], [0.5,  0.5, 0.5], [-0.5,  0.5, 0.5]);

  foreach my $triangle (0 .. 11) {
    foreach my $vertex (0 .. 2) {
      my $index  = $indices[3 * $triangle + $vertex];
      my $coords = $vertices[$index];
      my $normal = $$normals[$index];
      glNormal3f($$normal[0] + $xOff, $$normal[1] + $yOff, $$normal[2] + $zOff);
      glVertex3f($$coords[0] + $xOff, $$coords[1] + $yOff, $$coords[2] + $zOff);
    }
  }
}

sub floorNormals {
  my @grid = @_; #get the 3x3 grid to check to generate normals
  my @normals = ([-1, -1, -1], [1, -1, -1], [1, -1, 1], [-1, -1, 1],
                 [-1,  1, -1], [1,  1, -1], [1,  1, 1], [-1,  1, 1]);

  my @changeValues = ([0,3,1], [2,1,5], [8,5,7], [6,7,3]); #what grid unit can change which vertix (top or bottom)
  my $i;
  for ($i = 0, $i <= 3, $i++) { #calculate the bottom face first
    my $ch = $changeValues[$i]; #get the correct values for this vertex
    if ($grid[$$ch[0]] && $grid[$$ch[1]] && $grid[$$ch[2]]) { #are all three slots filled?
      $normals[$i] = [0, -1, 0]; #if so, set the normal to DOWN
    }
    elsif ($grid[$$ch[0]] && !$grid[$$ch[1]] && $grid[$$ch[2]]) {
      $normals[$i] = [(-1*cos(-90*$i))-(1*sin(-90*$i)), -1, (-1*sin(-90*$i))+(1*cos(-90*$i))]; #make our normal vector and transform to the correct angle
    }
    elsif ($grid[$$ch[0]] && $grid[$$ch[1]] && !$grid[$$ch[2]]) {
      $normals[$i] = [(1*cos(-90*$i))-(-1*sin(-90*$i)), -1, (1*sin(-90*$i))+(-1*cos(-90*$i))];  #this is an abomination of code
    }
  }

  for ($i = 4, $i <= 7, $i++) {
    my $ch = $changeValues[$i - 4]; #calculate based on the new $i value
    if (($grid[$$ch[0]] == 1) && ($grid[$$ch[1]] == 1) && ($grid[$$ch[2]] == 1)) { #are all three slots filled with floors?
      $normals[$i] = [0, 1, 0]; #if so, set the normal to UP
    }
    if (($grid[$$ch[0]] == 2) && ($grid[$$ch[1]] == 2) && ($grid[$$ch[2]] == 2)) { #are all three slots filled with walls?
      $normals[$i] = [(1*cos(-90*$i))-(1*sin(-90*$i)), 1, (1*sin(-90*$i))+(1*cos(-90*$i))]; #reverse the normal if so
    }
    elsif ($grid[$$ch[0]] && !$grid[$$ch[1]] && $grid[$$ch[2]]) {
      $normals[$i] = [(-1*cos(-90*$i))-(1*sin(-90*$i)), 1, (-1*sin(-90*$i))+(1*cos(-90*$i))]; #make our normal vector and transform to the correct angle
    }
    elsif ($grid[$$ch[0]] && $grid[$$ch[1]] && !$grid[$$ch[2]]) {
      $normals[$i] = [(1*cos(-90*$i))-(-1*sin(-90*$i)), 1, (1*sin(-90*$i))+(-1*cos(-90*$i))];  #this is an abomination of code
    }
  }
  return \@normals;
}
