step = 30;

for (r = [0:step:255]) { 
  for (g = [0:step:255]) { 
    for (b = [0:step:255]) { 
      translate([r, g, b]) color([r/255, g/255, b/255]) cube(step*0.75); 
    }
  }
}
