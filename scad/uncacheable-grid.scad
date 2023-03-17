// Copyright 2021 Google LLC.
// SPDX-License-Identifier: Apache-2.0

top_transform = true;
top_union = true;
N = 5;
size = 2;
$fn=12;

module grid(N)
{
  for (i=[0:N-1], j=[0:N-1]) translate([i * size, j * size, 0])
  // for (i=[0:N-1]) translate([i * size, 0, 0]) for (j=[0:N-1]) translate([0, j * size, 0])
    {
        sphere(d=1, $fn=16);

        difference() {
            h = 1 + (i + N * j) / pow(N, 2);
            hull() {
              cube(h, center=true);
              cylinder(h / 2 - 0.01, d=h * 1.3);
            }

            cylinder(h, r=0.45);
            translate([0, 0.5, 0])
              cylinder(h, r=0.2);
        }
    }
}

if (top_union)
  union() {
    if (top_transform)
      translate([0, 0, 1])
        grid(N);
    else
      grid(N);
  }
else if (top_transform)
  translate([0, 0, 1])
    grid(N);
else
  grid(N);
