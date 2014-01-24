#!/usr/bin/perl
require OpenGL;
package Graph::Render;

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
      OpenGL::glNormal3f($$coords[0] * $mul * 1.1, $$coords[1] * $mul * 1.1, $$coords[2] * $mul * 1.1); #calculate default normal map
      OpenGL::glVertex3f($$coords[0] * $mul, $$coords[1] * $mul, $$coords[2] * $mul); #calculate scale and push to the matrix
    }
  }
  glEnd; #end our cube object
}

sub drawFloor {
  my $xOff = shift; #get the X offset, etc. etc.
  my $yOff = shift;
  my $zOff = shift;
  my $normals = shift; #get the refrence for the NORMAL ma1s
  # A cubic world node
  my @indices = qw( 1 0 3  3 2 1); #hello again

  my @vertices = ([-0.5,  0.5, -0.5], [0.5,  0.5, -0.5], [0.5,  0.5, 0.5], [-0.5,  0.5, 0.5]);

  foreach my $triangle (0 .. 1) {
    foreach my $vertex (0 .. 2) {
      my $index  = $indices[3 * $triangle + $vertex];
      my $coords = $vertices[$index];
      my $normal = $$normals[$index];
      OpenGL::glNormal3f($$normal[0] + $xOff, $$normal[1] + $yOff, $$normal[2] + $zOff); #use our normal map provided instead of generating our own, account for offsets as well
      OpenGL::glVertex3f($$coords[0] + $xOff, $$coords[1] + $yOff, $$coords[2] + $zOff);
    }
  }
}

sub drawNormal {
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
      OpenGL::glVertex3f($$normal[0] + $xOff, $$normal[1] + $yOff, $$normal[2] + $zOff); #use our normal map provided instead of generating our own, account for offsets as well
      OpenGL::glVertex3f($$coords[0] + $xOff, $$coords[1] + $yOff, $$coords[2] + $zOff);
    }
  }
}
return 1;
