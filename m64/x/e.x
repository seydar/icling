` FILE:    e.x
` PURPOSE: compute d 
` METHOD:  wikipedia mathematical constant
` USAGE:   x:=e:=
` AUTHOR:  Eric Kee
` MODS:    mckeeman

sum := 0.0;
i := 1.0;
f := 1.0;           ` 0!
improving := true;  ` get it started
do improving ?
  newsum := sum + 1.0/f;
  f := f*i;
  i := i+1.0;
  improving := newsum > sum;
  sum := newsum;
od;
res := sum;
