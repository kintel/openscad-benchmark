// Copyright 2021 Google LLC.
// SPDX-License-Identifier: Apache-2.00

N = 3;
overlap = false;

union() {
  for (i=[0:N-1]) translate([i,0,0])
  for (j=[0:N-1]) translate([0,j,0])
    sphere(d=(overlap ? 1.1 : 0.9), $fn=50);
}
