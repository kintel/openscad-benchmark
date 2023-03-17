include <BOSL2/std.scad>

dishFn=30;
smoothFn=30;

echo("dishFn", dishFn);
echo("smoothFn", smoothFn);
minkowski() {
    diff("dish", keep="antenna")
        cube(100, center=true)
            attach([FRONT,TOP], overlap=33) {
                tag("dish") cylinder(h=33.1, d1=0, d2=95, $fn=dishFn);
                tag("antenna") cylinder(h=33.1, d=10, $fn=dishFn);
            }
    sphere(r=5, $fn=smoothFn);
}

include <BOSL2/std.scad>
//$fn=$preview ? 15 : 30;
*offset3d(1)
    bottom_half()
        difference() {
            cube(10, center=true);
            xscale(0.9) yscale(1.1)
                sphere(d=10);
        }
*offset3d(1)
    bottom_half()
        scale([1.2, 0.8, 1]) 
            cylinder(10, d=2, center=true);
    
    
*round3d(2, $fn=5)
    minkowski_difference() {
        union() {
            cube([120,70,70], center=true);
            cube([70,120,70], center=true);
            cube([70,70,120], center=true);
        }
        sphere(r=10, $fn=30);
    }
    
//round3d(10)
$fn=20;
*minkowski() {
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

include<BOSL2/std.scad>
*minkowski() {
prismoid([50,50],[30,30],h=40)
  position(RIGHT+TOP)
     cube([15,15,25],orient=RIGHT,anchor=LEFT+BOT);
    sphere(r=5, $fn=100);
}

