` FILE:     testAnd.x
` PURPOSE:  test many & in a row

b1 := true;

c1 := ~ (~b1);
c2 := ~ (~b1) & ~ (~b1);
c3 := ~ (~b1) & ~ (~b1) & ~ (~b1); 
c4 := ~ (~b1) & ~ (~b1) & ~ (~b1) & ~ (~b1);
c5 := ~ (~b1) & ~ (~b1) & ~ (~b1) & ~ (~b1) & ~ (~b1);
c6 := ~ (~b1) & ~ (~b1) & ~ (~b1) & ~ (~b1) & ~ (~b1) & ~ (~b1);

if c1 & c2 & c3 & c4 & c5 & c6 ? fi;
passedAnd := 6

