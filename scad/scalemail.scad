// Copyright 2021 Google LLC.
// SPDX-License-Identifier: Apache-2.0
//
// Author: Olivier Chafik (http://ochafik.com)
//
// This is my little print-in-place chain/scalemail project where I wanted to be
// able to draw on each scale separately, or across all of them (3D printing of
// large etchings may work best with support material, but for small text it's
// fine).
//
// This is my little chain/scalemail project where I wanted to be able to draw on each
// scale separately. OpenSCAD was taking too much time to render this, so I began
// a rendering optimization crusade (toyed with multithreading, lazier unions, faster
// union algorithms), current result (Feb 14th 2021) being this model renders in
// 68sec instead of 6minutes (5x faster) for use_sweep = false,
// and 1.5sec instead of 39sec (27x faster) for use_sweep = true.
//
// To reproduce this speedup before those changes are upstreamed (if they are):
//
// openscad --enable=fast-union --enable=lazy-union --enable=lazy-module --enable=flatten-children --enable=push-transforms-down-unions scalemail.scad -o scalemail.stl
//

// Precision and thickness of curves
$fn=20;
step = 0.01;//$preview ? 0.01 : 0.001;
thickness = 0.6;

use_sweep = false;

// Just leave this empty to get each tile numbered individually.
global_text = "\u2665";

// Width & height of the grid. Model will have N*N tiles.
N = 2;

// Parameters of the torus knot
n=4;
m=1;
height = 1.5;
r1 = 2;
r2 = 3;

plate_fill = 1.2;
epsilon = 0.01;
stride = r1 + r2;
zScale = height / 2;
plate_thickness = thickness * 1.5;
extra_pillar_height = thickness;
avgRadius = (r1 + r2) / 2;
inner_pillar_end_ratio = 0.7;
text_etching_depth = plate_thickness / 2;
individual_text_size = 2;
global_text_size_factor = 0.8;
global_text_size = N * stride * global_text_size_factor;
plate_z = -zScale - thickness / 2 - plate_thickness - extra_pillar_height;

function f(t) = [
  cos(m * t) * (avgRadius + (r2 - r1) / 2 * cos(n * t)),
  sin(m * t) * (avgRadius + (r2 - r1) / 2 * cos(n * t)),
  zScale * sin(n * t)
];


use <sweep.scad>
use <scad-utils/shapes.scad>
module draw_curve_sweep(p, thickness)
  sweep(circle(thickness / 2), construct_transform_path(p), true);

module draw_curve(p, thickness)
  if (use_sweep)
    draw_curve_sweep(p, thickness);
  else
    for (i=[0:len(p)-2])
        hull() {
            translate(p[i]) sphere(d=thickness);
            translate(p[i+1]) sphere(d=thickness);
        }

module torus_knot() draw_curve([for (t=[0:step:1]) f(t * 360)], thickness);

module etching_text(size, text)
  translate([0, 0, plate_z - epsilon])
    linear_extrude(height = text_etching_depth)
      mirror([-1, 0, 0])
        text(text = text, size = size, valign = "center", halign="center");

module scalemail()
  for (i=[0:N-1]) translate([i * stride,0,0])
    for(j=[0:N-1]) translate([0,j * stride,0])
      unit(global_text == "" ? str((N - j - 1) * N + (N - i - 1)) : undef);

if (global_text == "")
  scalemail();
else
  difference() {
    scalemail();
    translate([stride * N / 2 - stride / 2, stride * N / 2 - stride / 2, 0])
      etching_text(global_text_size, global_text);
  }

module unit(text) {
  torus_knot();

  // Draw the pillars from mid-height positions.
  mid_param_offset = 360 / n / 2;
  mid_angles = [for (i=[0:n-1]) i * 360/n + mid_param_offset];
  mid_heights = [for (a=mid_angles) f(a)];
  for (i=[0:n-1]) {
    pillar_end = mid_heights[i];
    angle = mid_angles[i];
    hull() {
      translate(pillar_end)
        sphere(d=thickness);
      translate([pillar_end[0], pillar_end[1], -zScale - thickness / 2 - extra_pillar_height])
        cylinder(thickness / 2 + extra_pillar_height, d=thickness);

      translate([inner_pillar_end_ratio * pillar_end[0], inner_pillar_end_ratio * pillar_end[1], -zScale - thickness / 2 - extra_pillar_height - plate_thickness])
        cylinder(plate_thickness, d=thickness);

      rotate([0, 0, (i + 0.5) * 360 / n])
        translate([plate_fill * (avgRadius - thickness / 2), 0, -zScale - thickness / 2 - plate_thickness])
          cylinder(h=plate_thickness, d=thickness);
    }
  }

  difference() {
    hull()
      for (i=[0:n-1])
        rotate([0, 0, (i + 0.5) * 360 / n])
          translate([plate_fill * (avgRadius - thickness / 2), 0, plate_z])
            cylinder(h=plate_thickness, d=thickness);

    if (!is_undef(text)) etching_text(individual_text_size, text);
  }
}