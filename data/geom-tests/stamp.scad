// Author: https://github.com/gringer
// Origin: https://github.com/openscad/openscad/issues/356#issuecomment-29764897

$fn=30;

translate([0,0,-2]) minkowski(){
    union(){
        cylinder(r=10+4, h = 2); // base
        translate([0,0,-2]){ // image
            cube([2,20,2], center = true);
            cube([20,2,2], center = true);
        }
    }
    cylinder(r1 = 0, r2 = 2, h = 2);  // bevel
}

translate([0,0,4]){ // handle
    difference() {
        cube([15,2,6], center = true);
        translate([0,0,-1]) cube([10,3,4], center = true);
    }
}