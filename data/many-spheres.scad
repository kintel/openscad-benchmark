$fn=128;

for (i=[0:100]) {
  rotate(i*360/100) translate([20,0,0]) sphere(r=10);
}
