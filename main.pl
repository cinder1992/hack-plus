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
glShadeModel(GL_FLAT);
glEnable(GL_DEPTH_TEST);
glMatrixMode(GL_PROJECTION);
glLoadIdentity;
gluPerspective(60, SCREEN_W / SCREEN_H, 1, 1000);
$camera{'x'} = 0; $camera{'y'} = 5; $camera{'z'} = -5;
#glTranslatef($camera{'x'},$camera{'y'},$camera{'z'});
glutInit();

$roomArea = <<EOR
..####..
.#.#..#.
#....#.#
#..#...#
#...#..#
#.#....#
.#..#.#.
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
$deltaYaw = 0;
$deltaPitch = 0;
$event = SDL::Event->new();    # create one global event
gluLookAt($camera{'x'}, $camera{'y'}, $camera{'z'}, 0, 0, 0, 0, 1, 0);
#glTranslatef(0, 0, -5);
while (!$exiting) {
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glRotatef($deltaYaw, 0, 1, 0);
  glRotatef($deltaPitch, 1, 0, 0);
  $deltaYaw = 0;
  $deltaPitch = 0;
  for my $x (0 .. $#room) {
    for my $y (0 .. $#{$room[$x]}) {
      my $char = $room[$x][$y];
      glMatrixMode(GL_MODELVIEW);
      glPushMatrix();
      glTranslatef($x - 3.5, 0, $y - 3.5);
      if ($char eq '.') {
        glColor3d(0,0.5,0);
        draw_cube(1, GL_TRIANGLES);
      }
      elsif ($char eq '#') {;
        glTranslatef(0, 1, 0);
        glColor3d(0.2,0.2,0.2);
        draw_cube(1, GL_TRIANGLES);
      }
      glPopMatrix();
    }
  } 
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

sub draw_cube
{
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
      glVertex3f($$coords[0] * $mul, $$coords[1] * $mul, $$coords[2] * $mul);
    }
  }
  glEnd;
}
