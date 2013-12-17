#!/usr/bin/perl
use strict;
use warnings;
use SDL;
use SDLx::App;
use SDLx::Surface;
use SDL::Image;
use SDLx::Rect;
use SDL::Event;
use SDLx::Text;
use constant SCREEN_W => 1024;
use constant SCREEN_H => 768;
my ($exiting, $time, $srcRect, $dstRect, $sprite, @particles, $event, @mouse, $colRect, $spawn);

my $app = SDLx::App->new(   #Create Window
  w => SCREEN_W,
  h => SCREEN_H,
  d => 32,
  title => "I'm a particle!",
  exit_on_quit => 1
);

$sprite = SDL::Image::load( 'img/guy.png' ) or die("Could not load image!"); #load the particle image
$srcRect = SDLx::Rect->new(0,0,10,20);
$dstRect = SDLx::Rect->new(SCREEN_W / 2, SCREEN_H / 2, 10, 20);
$event=SDL::Event->new();    # create one global event

while(!$exiting) {
  $app->draw_rect([0, 0, SCREEN_W, SCREEN_H], [255, 255, 255, 255]);
  $app->blit_by($sprite, $srcRect, $dstRect);
  $app->update();
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
      $spawn = 1
    }
  }
}

