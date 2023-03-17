$fn=60;

minkowski() {
    difference() {
        hull() {
            translate([3, 0, 0]) cube(0.5, center=true);
            cube(1, center=true);
        }
        translate([0, 0, 0])
            sphere(1);
    }
    sphere(1);
}
// Baseline: 10m55s
// Baseline w/ fast-csg & trust: 1m20s (MBP M2 Max: 19s)
// This PR w/ fast-csg & trust: 35s