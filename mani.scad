//cube();
for (i=[0:10])
    //translate([i*1.2, 0, 0])
        for (j=[0:10])
            translate([i*1.2, j*1.2, 0])
                sphere(1, $fn=30);

/*
minkowski() {
    hull() {
        cube();
        translate([1, 1, 1]) cube();
    }
    sphere(r=0.2, $fn=100);
}
//*/