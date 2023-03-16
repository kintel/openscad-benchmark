# OpenSCAD + Manifold + Minkowski = ❤️

Examples of rendering times w/ the upcoming Manifold rendering engine support in OpenSCAD (https://github.com/openscad/openscad/pull/4533)

## Box with filleted holes

* `manifold`: 11sec (2.7 cores utilization)
* `fast-csg`: 1m44sec 
* *normal*: ?

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

## Variation on BOSL2's antennas example

Taken [from BOSL2's docs](https://github.com/revarbat/BOSL2/wiki/Tutorial-Attachments#diffremove-keep), with extra minkowski.

* `manifold`: 35sec (5.8 cores utilization)
* `fast-csg`: 6m45sec 
* *normal*: ?

```js
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
```

## Smoothed weird cup using BOSL2 offset3d

* `manifold`: 4sec (2.5 cores utilization)
* `fast-csg`: 1m34sec 
* *normal*: 4m31sec

![image](https://user-images.githubusercontent.com/273860/225525640-b87aba18-10eb-42fb-8fa1-ad0a46590ea3.png)

```js
include <BOSL2/std.scad>
$fn=$preview ? 15 : 30;
offset3d(1)
    bottom_half()
        difference() {
            cube(10, center=true);
            xscale(0.9) yscale(1.1)
                sphere(d=10);
        }
```

## Minkowski of minkowski difference!

* `manifold`: 40sec (1.7 cores utilization)
* `fast-csg`: 42sec (!)
* *normal*: 3m43sec

<img width="520" alt="image" src="https://user-images.githubusercontent.com/273860/225530675-75e1ea6e-bb0d-4c39-897c-89c119b0e12d.png">

```js
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
```