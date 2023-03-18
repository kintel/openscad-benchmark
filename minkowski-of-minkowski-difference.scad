include <BOSL2/std.scad>
$fn=20;
minkowski() {
    minkowski_difference() {
        union() {
            cylinder(120, d=100, center=true);
            rotate([90, 0, 0]) cylinder(120, d=70, center=true);
            rotate([0, 90, 0]) cylinder(120, d=70, center=true);
        }
        sphere(r=10);
    }
    sphere(r=5);
}