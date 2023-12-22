NUM=10;

for (z=[0:NUM-1])
  for (y=[0:NUM-1])
    for (x=[0:NUM-1])
      translate ([1.2*x, 1.2*y, 1.2*z]) cube();
