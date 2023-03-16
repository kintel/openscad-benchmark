# OpenSCAD + Manifold + Minkowski = ❤️

Examples of rendering times w/ the upcoming Manifold rendering engine support in OpenSCAD (https://github.com/openscad/openscad/pull/4533)

## Box with filleted holes

`manifold`: 11sec (2.7 cores utilization)
`fast-csg`: 1m44sec 
*normal*: ??

<img width="675" alt="image" src="https://user-images.githubusercontent.com/273860/225524855-819b52fb-534a-4e63-ab97-74b21cb9893d.png">

```js
include <BOSL2/std.scad>

dims=[100, 200, 30];
holes=[5, 10];

border=10;

smoothRadius=2;
smoothFn=$preview ? 5 : 30;

holeDiam=10;
holeFn=$preview ? 10 : 30;

minkowski() {
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
```