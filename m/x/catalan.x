` FILE:    catalan.x
` PURPOSE: compute Catalan number
` USAGE:   xcom x/fact.x x/catalan.x
` METHOD:  wikipedia catalan number
` AUTHOR:  McKeeman
` NOTE:    fails for n>6 because of 32-bit overflow

t1 := fact := n+0;
t2 := (n+1)*t1;
t3 := fact := 2*n;

res := t3/(t1*t2);
 