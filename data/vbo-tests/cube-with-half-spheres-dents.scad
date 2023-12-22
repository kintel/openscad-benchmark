// Copyright 2021 Google LLC.
// SPDX-License-Identifier: Apache-2.0
//
// Context: https://github.com/openscad/openscad/pull/3636
//
// openscad --enable=fast-union cube-with-half-spheres-dents.scad -o cube-with-half-spheres-dents.stl
// Runs in 1min8sec with the feature, 4min25sec without (almost 4x speedup)

N = 5;
overlap=true;

difference() {
  translate([-0.5, -0.5, -0.5]) cube([N, N, 0.5]);
  // Explicit union here, as difference isn't optimized yet (only union is).
  union() {
      for (i=[0:N-1], j=[0:N-1])
        translate([i, j, 0])
          sphere(d=(overlap ? 1.1 : 0.9), $fn=100);
  }
}
