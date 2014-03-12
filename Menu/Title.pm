#!/usr/bin/perl
use strict;
use warnings;


package Menu::Title;
use SDL;
use SDLx::Rect;
use SDLx::Surface;
use SDL::Event;
use SDL::Events;
use Data::Dumper;

sub toMenu {
  my $self = shift;
  my $order = shift;
  my $ghashRef = shift;
  my $arrayRef = shift;
  my $subMenu = shift;
  my $xPos = shift;
  my $yPos = 0;
  my $i;
  my $offset = 0;
  for ($i = 0; $i <= $#{$order}; $i++) {
    my $key = $$order[$i];
    my $hashRef = {_name => " $key ", _xPos => $xPos, _data => [],  _selected => 0, _submenu => $subMenu};
    $$arrayRef[$i - $offset] = $hashRef;
    $$hashRef{_event} = sub { menuEvent($self, $hashRef, @_) };
    $$hashRef{_draw} = sub { menuShow($self, $hashRef, @_) };
    my @chars = split('', $$hashRef{_name});
    if (ref($$ghashRef{$key}) eq "HASH") {
      $offset++;
      $i++;
      toMenu($self, $$order[$i], $$ghashRef{$key}, $$hashRef{_data}, 1, $xPos);
    }
    else {
      $$hashRef{_data} = $$ghashRef{$key};
    }
    foreach my $char (@chars) {
      $xPos += 8 if !$subMenu;
    }
    if ($subMenu) {
      $yPos +=16;
    }
    else {
      $yPos = 0;
    }
    $$hashRef{_yPos} = $yPos;
  }
}

sub init {
  my $self = {
    _font => SDLx::Surface->load( "Menu/font.png" ),
    _selectFont => SDLx::Surface->load( "Menu/fontSelect.png" ),
    _data => [],
    _drawers => [],
    _events => []
  };
  my $data = shift;
  my $order = shift;
  my $app = shift;
  toMenu($self, $order, $data, $self->{_data}, 0, 0);
  initHandlers($app, $self, $self->{_data}, 0);
  initDrawHandlers($app, $self, $self->{_data}, 1);
  reInitHandlers($self, $app);
  return $self;
}

sub reInitHandlers {
  my ($self, $app) = @_;
  $app->add_event_handler(sub{runEventHandlers($self, @_)});
  $app->add_show_handler(sub{runDrawHandlers($self, @_)});
}

sub initHandlers {
  my $app = shift;
  my $self = shift;
  my $menu = shift;
  my $reset = shift;

  if($reset) { 
    $self->{_events} = [];
  }

  foreach my $menuItem (0 .. $#{$menu}) {
    push($self->{_events}, @$menu[$menuItem]->{_event});
  }
}

sub initDrawHandlers {
  my $app = shift;
  my $self = shift;
  my $menu = shift;
  my $reset = shift;
  if ($reset) {
    $self->{_drawers} = [];
  }
  foreach my $menuItem (0 .. $#{$menu}) {
    push($self->{_drawers}, @$menu[$menuItem]->{_draw});
  }
}

sub runDrawHandlers {
  my ($self, $delta, $app) = @_;
  foreach my $drawer (@{$self->{_drawers}}) {
    &$drawer($delta, $app);
  }
}

sub runEventHandlers {
  my ($self, $event, $app) = @_;
  my $ret = 0;
  my @events = map { @$_ } $self->{_events};
  foreach my $eventHandler (@events) {
    $ret = &$eventHandler($event, $app) + $ret;
  }
  if (!$ret) {
    initDrawHandlers($app, $self, $self->{_data}, 1);
    initHandlers($app, $self, $self->{_data}, 1);
  }
}


sub menuEvent {
  my ($self, $menuItem, $event, $app) = @_;
  my $width = length($$menuItem{_name}) * 8;
  my $rect = SDLx::Rect->new($$menuItem{_xPos}, $$menuItem{_yPos}, $width, 16);
  if ($event->type == SDL_MOUSEBUTTONDOWN) {
    if ($event->button_button == SDL_BUTTON_LEFT) {
      my $x = $event->button_x;
      my $y = $event->button_y;
      if ($rect->collidepoint($x, $y)) {
        if(ref($$menuItem{_data}) eq "CODE") {
          $menuItem->{_selected} = 1;
          &{$$menuItem{_data}};
          return 0;
        }
        else {
          $menuItem->{_selected} = 1;
          initDrawHandlers($app, $self, $$menuItem{_data}, 0);
          initHandlers($app, $self, $$menuItem{_data}, 1);
          return 1;
        }
      }
      else {
        return 0;
      }
    }
  }
  if ($event->type == SDL_MOUSEMOTION) {
    my $x = $event->motion_x;
    my $y = $event->motion_y;
    if ($rect->collidepoint($x, $y)) {
      $menuItem->{_selected} = 1;
      return 1;
    }
    else {
      $menuItem->{_selected} = 0;
      return 1;
    }
  }
  return 1;
}

sub menuShow {
  my ($self, $menuItem, $delta, $app) = @_;
  my @strArray = split("", $$menuItem{_name});
  foreach my $i (0 .. $#strArray) {
    my $x = $$menuItem{_xPos} + ($i * 8);
    my $char = ord($strArray[$i]);
    my @coords = (0,0);
    if($char >= 256) {
      $char = 255;
    }
    while($char > 15) {
      $char -= 16;
      $coords[1]++;
    }
    $coords[0] = $char;
    @coords = ($coords[0] * 8, $coords[1] * 16);
    if($$menuItem{_selected}) {
      $self->{_selectFont}->blit($app, [$coords[0], $coords[1], 8, 16], [$x, $$menuItem{_yPos}, 8, 16]);
    }
    else {
      $self->{_font}->blit($app, [$coords[0], $coords[1], 8, 16], [$x, $$menuItem{_yPos}, 8, 16]);
    }
  }
}
return 1;
