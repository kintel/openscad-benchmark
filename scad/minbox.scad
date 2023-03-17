include <BOSL2/std.scad>

dims=[100, 200, 30];
holes=[5, 10];

border=10;

smoothRadius=2;
smoothFn=$preview ? 5 : 30;

holeDiam=10;
holeFn=$preview ? 10 : 30;

minkowski()
{
    union() {
        difference() {
            cube(dims);
            
            translate([border, border, border])
                cube(dims - 2 * [border, border, 0]);
                
            for (i=[0:holes[0]], j=[0:holes[1]]) 
                translate([
                    border + (i + 0.5) * (dims[0] - 2 * border) / (holes[0] + 1),
                    border + (j + 0.5) * (dims[1] - 2 * border) / (holes[1] + 1),
                    0
                ])
                    cylinder(h = border, d=holeDiam, $fn=holeFn);
        }
    }
    sphere(smoothRadius, $fn=smoothFn);
}
