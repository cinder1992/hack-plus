#!/usr/bin/perl
use strict;
use warnings;
use SDL;
use SDLx::App;
use SDLx::Rect;
use SDL::Event;
use OpenGL qw(:all);
use constant SCREEN_W => 800;
use constant SCREEN_H => 600;
my ($exiting, $srcRect, $dstRect, $sprite, $event, @mouse, $roomArea, @room);

my $app = SDLx::App->new(   #Create Window
  w => SCREEN_W,
  h => SCREEN_H,
  title => "I'm a particle!",
  exit_on_quit => 1,
  gl => 1
);
#define openGL functions
glEnable(GL_DEPTH_TEST);
glMatrixMode(GL_PROJECTION);
glLoadIdentity;
gluPerspective(60, SCREEN_W / SCREEN_H, 1, 1000);
glTranslatef(0, 0, -20);
glutInit();

$roomArea = <<EOR
..####..
.#....#.
#......#
#......#
#......#
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

$event = SDL::Event->new();    # create one global event

while (!$exiting) {
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glRotatef(0.1, 1, 0, 1);
  for my $x (0 .. $#room) {
    for my $y (0 .. $#{$room[$x]}) {
      my $char = $room[$x][$y];
      glMatrixMode(GL_MODELVIEW);
      glPushMatrix();
      glTranslatef($x, 0, $y);
      if ($char eq '.') {
        glColor3d(0,0.5,0);
        glutSolidCube(1);
      }
      elsif ($char eq '#') {;
        glTranslatef(0, 1, 0);
        glColor3d(0.2,0.2,0.2);
        glutSolidCube(1);
      }
      glPopMatrix();
    }
  } 
  $app->sync();
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
