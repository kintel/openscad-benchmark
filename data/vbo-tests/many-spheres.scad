$fn=128;
NUM=100;

for (i=[0:NUM]) {
  rotate(i*360/NUM) translate([20,0,0]) sphere(r=10);
}
