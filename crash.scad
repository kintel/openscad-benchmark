segments=10;
rows=2;

minkowski() {
union() {
for(i=[0:segments]) {
   for(j=[0:rows]) {
      polyhedron(
         points=[
            [
               sin(360/segments*i)*sqrt(rows-j+1),
               cos(360/segments*i)*sqrt(rows-j+1),
               j
            ],
            [
               sin(360/segments*(i+1))*sqrt(rows-j+1),
               cos(360/segments*(i+1))*sqrt(rows-j+1),
               j
            ],
            [
               sin(360/segments*(i+0.5))*sqrt(rows-j),
               cos(360/segments*(i+0.5))*sqrt(rows-j),
               j+1
            ]],triangles=[[0,1,2]]);
   }
}
}
cube([0.1,0.1,0.1],center=true);
}