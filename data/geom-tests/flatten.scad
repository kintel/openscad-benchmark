//*
$fn=20;

// translate([1, 0, 0]) {
//   cube(1, center=true);
//   translate([0.1, 0, 0])
//     cube(1.2, center=true);
// }

module A() {
  sphere(1);
  translate([1, 0, 0]) {
    cube(1, center=true);
    translate([0.1, 0, 0])
      cube(1.2, center=true);
  }
}

for (i=[0:3])
    translate([i*2, 0, 0]) A();


//*/
// translate([1, 0, 0]) { cube(); sphere(); }
// translate([1, 0, 0]) { cube(); sphere(); }