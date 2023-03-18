include <BOSL2/std.scad>
$fn=$preview ? 15 : 30;
offset3d(1)
    bottom_half()
        difference() {
            cube(10, center=true);
            xscale(0.9) yscale(1.1)
                sphere(d=10);
        }