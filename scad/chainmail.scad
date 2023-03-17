// Copyright 2021 Google LLC.
// SPDX-License-Identifier: Apache-2.0
//
// This one has local overlaps all over the place, and needs a heuristic to find non-overlapping subsets.
// (that's under development, expect CGAL::hilbert_sort, CGAL::Union_find and hopefully some good benchmarks!)

$fn=20;
step = 0.01; //$preview ? 0.01 : 0.001;
thickness = 0.5;
height = 1;
r1 = 2;
r2 = 3;

N = 5;
stride = r1 + r2;

// Use sweep.scad
use_sweep = false;

function f(t, r1, r2, h, m=4, n=1) =
  let (avgRadius = (r1 + r2) / 2)
  [
    cos(n * t) * (avgRadius + (r2 - r1) / 2 * cos(m * t)),
    sin(n * t) * (avgRadius + (r2 - r1) / 2 * cos(m * t)),
    h * sin(m * t)
  ];

use <list-comprehension-demos/sweep.scad>
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

module torus_knot() {
  points = [for (t=[0:step:1]) f(t * 360, r1=r1, r2=r2, h=height)];
  draw_curve(points, thickness);
}

translate([-N * stride / 2 + stride / 2, -N * stride / 2 + stride / 2, height + thickness / 2]) {
  for (i=[0:N-1], j=[0:N-1]) translate([i * stride, j * stride,0])
    torus_knot();
}
