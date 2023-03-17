// Copyright 2021 Google LLC.
// SPDX-License-Identifier: Apache-2.0

N = 3;
overlap = false;

union() {
  for (i=[0:N-1], j=[0:N-1])
    translate([i,j,0])
      sphere(d=(overlap ? 1.1 : 0.9), $fn=50);
}
