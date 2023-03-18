include <BOSL2/std.scad>
minkowski() {
    diff("dish", keep="antenna")
        cube(100, center=true)
            attach([FRONT,TOP], overlap=33) {
                tag("dish") cylinder(h=33.1, d1=0, d2=95, $fn=100);
                tag("antenna") cylinder(h=33.1, d=10, $fn=100);
            }
    sphere(r=5, $fn=100);
}