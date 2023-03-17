| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `s/render manifold 'scad/spheres-grid.scad'` | 250.5 | 250.5 | 250.5 | 3.18 |
| `s/render manifold 'scad/spheres-grid.scad' 'overlap=true'` | 329.3 | 329.3 | 329.3 | 4.18 |
| `s/render manifold 'scad/spheres-grid.scad' 'overlap=false'` | 254.6 | 254.6 | 254.6 | 3.23 |
| `s/render manifold 'scad/spheres_nested_for_loops.scad'` | 78.8 | 78.8 | 78.8 | 1.00 |
| `s/render manifold 'scad/spheres_nested_for_loops.scad' 'overlap=true'` | 91.1 | 91.1 | 91.1 | 1.16 |
| `s/render manifold 'scad/spheres_nested_for_loops.scad' 'overlap=false'` | 94.9 | 94.9 | 94.9 | 1.20 |
| `s/render manifold 'scad/spheres_single_for_loop.scad'` | 120.2 | 120.2 | 120.2 | 1.52 |
| `s/render manifold 'scad/spheres_single_for_loop.scad' 'overlap=true'` | 178.1 | 178.1 | 178.1 | 2.26 |
| `s/render manifold 'scad/spheres_single_for_loop.scad' 'overlap=false'` | 119.1 | 119.1 | 119.1 | 1.51 |
| `s/render fastcsg 'scad/spheres-grid.scad'` | 946.0 | 946.0 | 946.0 | 12.00 |
| `s/render fastcsg 'scad/spheres-grid.scad' 'overlap=true'` | 945.6 | 945.6 | 945.6 | 12.00 |
| `s/render fastcsg 'scad/spheres-grid.scad' 'overlap=false'` | 935.8 | 935.8 | 935.8 | 11.87 |
| `s/render fastcsg 'scad/spheres_nested_for_loops.scad'` | 240.4 | 240.4 | 240.4 | 3.05 |
| `s/render fastcsg 'scad/spheres_nested_for_loops.scad' 'overlap=true'` | 198.5 | 198.5 | 198.5 | 2.52 |
| `s/render fastcsg 'scad/spheres_nested_for_loops.scad' 'overlap=false'` | 246.9 | 246.9 | 246.9 | 3.13 |
| `s/render fastcsg 'scad/spheres_single_for_loop.scad'` | 263.0 | 263.0 | 263.0 | 3.34 |
| `s/render fastcsg 'scad/spheres_single_for_loop.scad' 'overlap=true'` | 245.8 | 245.8 | 245.8 | 3.12 |
| `s/render fastcsg 'scad/spheres_single_for_loop.scad' 'overlap=false'` | 262.0 | 262.0 | 262.0 | 3.32 |
