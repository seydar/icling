` FILE:    pi.x
` PURPOSE: compute pi to n terms
` METHOD:  4*(1 - 1/3 + 1/5 - 1/7 + 1/9...)
`          Number of terms is input
`          It takes a LOT of terms to get any accuracy at all

p2 := 0.0;
i := 1;
do i<4*nterms ? 
  t  := 1.0/i2r(i); 
  p1 := p2 + t;                ` too high
  i  := i + 2;
  t  := 1.0/i2r(i);
  p2 := p1 - t;                ` too low
  i  := i + 2;
od;

res := 4.0*p2;                 ` best result
delta := 1.0/i2r(nterms);      ` previous increment
