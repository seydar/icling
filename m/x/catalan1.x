` FILE:    catalan1.x
` PURPOSE: compute Catalan number
` USAGE:   xcom x/catalan1.x
` METHOD:  wikipedia catalan number
` AUTHOR:  Hong Lu
` NOTE:    fails for n>16 because of 32-bit overflow

c := 1;
i := 1;
do i<n ?  c := c*(4*i+2)/(i+2); i := i+1; od;

res := c;
