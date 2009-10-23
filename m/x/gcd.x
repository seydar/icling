` FILE:     gcd.x
` PURPOSE:  compute greatest common divisor of two integers
` METHOD:   Euclid
` AUTHOR:   Andrew Parker
` MODS:     mckeeman

a := inputa;
b := inputb;

do b~=0 ?
  r,a := a//b,b;
  b := r;
od;
gcd := a;