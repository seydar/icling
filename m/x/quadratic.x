` FILE:    quadratic.x
` PURPOSE: solve $ax^2+bx+c=0$
` METHOD:  standard formula
` USAGE:   \verb!>> xcom x/sqrt.x x/quadratic.x!
` AUTHOR:  Ashwin Ramaswamy
` MODS:    McKeeman

if ~(a <= 0.0 & a >=0.0) ?            ` $ax^2 + bx + c = 0$
  root := sqrt :=  b*b - 4.0*a*c;
  res1 := -(b + root)/2.0;
  res2 := -(b - root)/2.0;
:: ~(b<=0.0 & b>=0.0) ?               ` $bx + c = 0$
  res1 := -c/b;
  res2 := -c/b;
fi;
