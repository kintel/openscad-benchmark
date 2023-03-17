// Copyright 2021 Google LLC.
// SPDX-License-Identifier: Apache-2.0

N = 5;

// When this is true, we end up with lots of overlaps, which goes in the way of some optimizations but is still very fast with fast-csg
overlap = false;

// A simple grid of smooth spheres
union() {
  for (i=[0:N-1], j=[0:N-1])
    translate([i, j, 0])
      sphere(d=(overlap ? 1.1 : 0.9), $fn=50);
}