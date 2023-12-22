include <BOSL2/std.scad>

z=6;

bottom_half(z=z)
    import("maze-manifold.stl");
    //import("maze-fastcsg.stl");