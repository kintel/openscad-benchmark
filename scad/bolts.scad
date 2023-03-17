use <threadlib/threadlib.scad>
use <threads.scad>

//minkowski()
{
    union() {
        for (M=[1:8])
            translate([M*M,0,0])
                bolt(str("M", M), turns=5, higbee_arc=30);

        for (i=[0:8])
            let(M=4+i)
                translate([i*20,20,0])
                    nut(str("M", M, "x0.5"), turns=10, Douter=16);
    }
    //sphere(d=0.5, $fn=10);
}
//bolt("M4", turns=5, higbee_arc=30);
//nut("M12x0.5", turns=10, Douter=16);