#!/usr/bin/perl
use strict;
#use warnings;
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

SDL::Mouse::show_cursor(SDL_DISABLE); #disable the mouse's visibility inside our app
$app->grab_input(SDL_GRAB_ON); #grab our input FPS-style
#define openGL functions
my @whitespec = (1,1,1); #Specular colour
my @blackamb = (0,0,0); #black ambient light
my @whitedif = (1,1,1); #white diffuse light
glEnable(GL_DEPTH_TEST); #enable Depth, Lighting, Light no. 0, auto-normaling
glEnable(GL_LIGHTING);
glEnable(GL_LIGHT0);
glEnable(GL_NORMALIZE);
glEnable(GL_COLOR_MATERIAL);
glMatrixMode(GL_PROJECTION); #alter the projection matrix
glLoadIdentity; #reset the selected matrix
glLightfv_p(GL_LIGHT0, GL_SPECULAR, @whitespec, 0); #set the light specular, ambient, and diffuse materials
glLightfv_p(GL_LIGHT0, GL_AMBIENT, @blackamb, 0);
glLightfv_p(GL_LIGHT0, GL_DIFFUSE, @whitedif, 0);
gluPerspective(60, SCREEN_W / SCREEN_H, 1, 1000); #set up the perspective and prepare the rendering canvas
$camera{'x'} = 0; $camera{'y'} = 15; $camera{'z'} = -15; #define our camera
glutInit(); #init glut, in case we ever need to use it 

#define the test room
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
@room = (); #defile the test-room's split array

my $virtX = 0;

foreach my $line (split("\n", $roomArea)) { #turn the room into a proper 2d array
  foreach my $char (split("", $line)) {
    push @{$room[$virtX]}, $char;
    $virtX++;
  }
  $virtX = 0; #Reset virtual X
}

$deltaYaw = 0;
$deltaPitch = 0;

$event = SDL::Event->new();    # create one global event
gluLookAt($camera{'x'}, $camera{'y'}, $camera{'z'}, 0, 0, 0, 0, 1, 0); #look at the center of our scene
while (!$exiting) { #main loop
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); #clear the depth and colour, effectively clearing the screen
  glRotatef($deltaYaw, 0, 1, 0); #rotate the scene according to mouse movement
  glRotatef($deltaPitch, 1, 0, 0); #^
  $deltaYaw = 0; #reset delta-yaw and delta-pitch
  $deltaPitch = 0;
  positionLight(drawWorld(@room)); #position our light based on what the world-drawing returns
  $app->sync(); #render time!
  handleEvents();
}

sub quitEvent {
  exit;
}

sub handleEvents {
  SDL::Events::pump_events(); #get all events
  my $key = ($event->type == 2 or $event->type == 3) ? $event->key_sym : ""; #make $key equal to the key pressed or released
  while(SDL::Events::poll_event($event)) { 
    if($event->type == SDL_QUIT) { #are we quitting?
      &quitEvent();
    }
    elsif($event->type == 4) { #did someone move the mouse?
      $deltaYaw = -$event->motion_xrel; #set deltaYaw and deltaPitch
      $deltaPitch = -$event->motion_yrel;
    }
    elsif($key eq ord('q')) { #quit if we hit Q
      &quitEvent();
    }
  }
}

sub draw_cube {
  my $mul = shift; #cube scale
  my $type = shift; #cube render type (wireframe, etc.
  # A simple cube
  my @indices = qw( 6 7 3  3 2 6
                    5 6 2  2 1 5
                    4 5 1  1 0 4
                    7 4 0  0 3 7
                    5 4 7  7 6 5
                    0 1 2  2 3 0); #indices grouped by triangle

  my @vertices = ([-0.5, -0.5, -0.5], [0.5, -0.5, -0.5], [0.5, -0.5, 0.5], [-0.5, -0.5, 0.5],
                  [-0.5,  0.5, -0.5], [0.5,  0.5, -0.5], [0.5,  0.5, 0.5], [-0.5,  0.5, 0.5]); #all the vertexs of the cube

  glBegin($type); #begin our cube object
  foreach my $triangle (0 .. 11) { #count by triangle
    foreach my $vertex (0 .. 2) { #count by vertex
      my $index  = $indices[3 * $triangle + $vertex]; #get our vertex number from $indices
      my $coords = $vertices[$index]; #actually get the vertex
      glNormal3f($$coords[0] * $mul * 1.1, $$coords[1] * $mul * 1.1, $$coords[2] * $mul * 1.1); #calculate default normal map
      glVertex3f($$coords[0] * $mul, $$coords[1] * $mul, $$coords[2] * $mul); #calculate scale and push to the matrix
    }
  }
  glEnd; #end our cube object
}

sub drawWorld { #duh?
  my @world = @_;
  glPushMatrix(); #Reset Matrix
  my $maxY = 0;
  glBegin(GL_TRIANGLES); #begin world rendering as a set of triangles (GL_QUADS, or squares, tend to be slower)
  my @offset = (0, 0,0); #temp value, replace with actual middle of world.
  my @lightPos;
  for my $x (0 .. $#world) {
    glTranslatef(1,0,0); #translate according to our coordinate
    for my $y (0 .. $#{$world[$x]}) {
      my @grid = fillGrid($x, $y, \@world); #create the normal influence grid
      my $i; #define i in a C89-like manner
      my $char;
      print @grid; print "\n\n";
      $char = $world[$x][$y]; #get our current character from the world
      my @localOffset = ($offset[0] + $x, $offset[1], $offset[2] + $y); #calculate the offset of the vertices
      if ($char eq '.') { #are we a floor?
        glColor3d(0,0.5,0); #we're green
        drawFloor($localOffset[0], $localOffset[1], $localOffset[2], floorNormals(@grid)); #and we draw our floor with the offsets and normals
      }
      elsif ($char eq '#') {; #are we a wall?
        ##wall rendering disabled and replaced with floor rendering temporarily##
        glColor3d(0,0.5,0);
        drawFloor($localOffset[0], $localOffset[1], $localOffset[2], floorNormals(@grid));
        glColor3d(0.2,0.2,0.2);
      }
      elsif ($char eq 'l') { #are we a light?
        @lightPos = ($x, 1.5, $y); #set the position of our light
        glColor3d(0,0.5,0); #make the floor green
        drawFloor($localOffset[0], $localOffset[1], $localOffset[2], floorNormals(@grid)); #once again draw the floor
      }
      $maxY=$y; #set our max-y for the translate to reset our rendering... typewriter style :)
    }
    glTranslatef(0,0,-$maxY-1); #reset our Y offset to 0
  } 
  glEnd(); #stop rendering the world
  glPopMatrix(); #pop this to the matrix
  return @lightPos; #return where our light should go
}

sub positionLight {
  my @light = @_;
  glLightfv_p(GL_LIGHT0, GL_POSITION, @light, 0); #put the light where it should be
  glLightfv_p(GL_LIGHT0, GL_POSITION, $light[0]+2,$light[1]+2,$light[2]+2, 1);
}

sub drawFloor {
  my $xOff = shift; #get the X offset, etc. etc.
  my $yOff = shift;
  my $zOff = shift;
  my $normals = shift; #get the refrence for the NORMAL maps
  # A cubic world node
  my @indices = qw( 6 7 3  3 2 6
                    5 6 2  2 1 5
                    4 5 1  1 0 4
                    7 4 0  0 3 7
                    5 4 7  7 6 5
                    0 1 2  2 3 0); #hello again

  my @vertices = ([-0.5, -0.5, -0.5], [0.5, -0.5, -0.5], [0.5, -0.5, 0.5], [-0.5, -0.5, 0.5],
                  [-0.5,  0.5, -0.5], [0.5,  0.5, -0.5], [0.5,  0.5, 0.5], [-0.5,  0.5, 0.5]);

  foreach my $triangle (0 .. 11) {
    foreach my $vertex (0 .. 2) {
      my $index  = $indices[3 * $triangle + $vertex];
      my $coords = $vertices[$index];
      my $normal = $$normals[$index];
      glNormal3f($$normal[0] + $xOff, $$normal[1] + $yOff, $$normal[2] + $zOff); #use our normal map provided instead of generating our own, account for offsets as well
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

sub fillGrid {
  my $i;
  my $char;
  my @grid;
  my $x = shift;
  my $y = shift;
  my $world = shift;
  for ($i = 0, $i <= 2, $i++) { #ahh, C-like for loops, how I missed thee...
    if ($x > 0 && $y > 0) { #make sure we aren't out of bounds
      my $lx = $x-1;
      my $ly = $y-1+$i;
      $char = $$world[$lx][$li]; #set our char correctly
      push(@grid, 
        $char eq '#' ? 2 : #if we're a wall, send 2 to @grid
        $char eq " " ? 0 : #if we're blank, or a whitespace, send 0 to @grid
        $char eq "" ?  0 : 1
      )
    }
    else {push(@grid,0);} #just push 0 if we're out of the world
  }
  for ($i = 0, $i <= 2, $i++) { #rinse and repeat for the next two x values
    my $lx = $x;
    my $ly = $y-1+$i;
    if($y < 0 || $y > 7) { push(@grid, 0) }
    else {
      $char = $$world[$lx][$ly];
      push(@grid,
        $char eq '#' ? 2 :
        $char eq " " ? 0 : 
        $char eq ""  ? 0 : 1
      )
    }
  }
  for ($i = 0, $i <= 2, $i++) { #rinse and repeat for the next two x values
    if ($x < 7 && $y < 7) {
      my $lx = $x+1;
      my $ly = $y-1+$i;
      $char = $$world[$lx][$ly];
      push(@grid,
        $char eq '#' ? 2 :
        $char eq " " ? 0 :
        $char eq ""  ? 0 : 1
      )
    }
    else {push(@grid,0)}
  }
  return @grid;
}

